// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../VerifyKey.sol";
import "./IGovernanceAccrue.sol";
import "../../initialization/InitializationExecuteManager.sol";
import "../../../openzeppelin-contracts/utils/Counters.sol";
import "../../../openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../../../openzeppelin-contracts/access/IAccessControl.sol";
import "../../../openzeppelin-contracts/security/ReentrancyGuard.sol";
import "../../../openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract GovernanceAccrue is
    InitializationExecuteManager,
    VerifyKey,
    ReentrancyGuard,
    IGovernanceAccrue
{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Address for address;

    IERC20 public immutable token; // token for vote
    address public immutable treasury;
    Counters.Counter internal _agendaId; // agenda id

    mapping(uint => mapping(uint => mapping(address => UserInfo)))
        public userInfos; // agenda id => sector idx => user info
    mapping(uint => Agenda) private _agendas; // agenda infos

    constructor(
        address _token,
        address _treasury,
        bytes32 _validatorRole,
        bytes32 _setterRole,
        address _roleManager,
        address _executeManager,
        address _blackList
    )
        InitializationExecuteManager(
            _validatorRole,
            _setterRole,
            _roleManager,
            _executeManager,
            _blackList
        )
    {
        if (!_token.isContract())
            revert InvalidAddress("recipientRole", _token);
        if (!_treasury.isContract())
            revert InvalidAddress("treasury", _treasury);

        token = IERC20(_token);
        treasury = _treasury;

        // regist selector
        _registFunctionSelector("vote", IGovernanceAccrue.vote.selector);
        _registFunctionSelector("cancel", IGovernanceAccrue.cancel.selector);
    }

    /**
     *  @dev create agenda
     *  @param purpose agenda purpose
     *  @param minVoteAmount min amount of voting
     *  @param coolTime cancel vote time lock
     *  @param cancelLock cancel lock time for next cancel
     */
    function create(
        bytes32 purpose,
        uint minVoteAmount,
        uint coolTime,
        uint cancelLock
    )
        external
        virtual
        onlyExecutable(this.create.selector)
        onlyValidator
        isNotBlackList(msg.sender)
    {
        _agendaId.increment();

        uint newId = _agendaId.current();

        Agenda storage agenda = _agendas[newId];

        agenda.minVoteAmount = minVoteAmount;
        agenda.createdTime = block.timestamp;
        agenda.coolTime = coolTime;
        agenda.purpose = purpose;
        agenda.cancelLock = cancelLock;

        emit Created(newId, purpose, block.timestamp);
    }

    /**
     *  @dev add voting sector to agenda
     *  @param agendaId target agenda id
     *  @param to function executing target address
     *  @param purpose sector purpose
     *  @param callData executing calldata
     */
    function addSector(
        uint agendaId,
        address to,
        bytes32 purpose,
        bytes calldata callData
    )
        external
        virtual
        onlyExecutable(this.addSector.selector)
        onlyValidator
        isNotBlackList(msg.sender)
    {
        uint id = agendaId;
        bytes32 _purpose = purpose;

        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);
        if (_purpose == "") revert EmptyPurpose();

        unchecked {
            _agendas[id].cNum += 1;
        }

        _agendas[id].sectors.push(
            Sector(
                true,
                0,
                0,
                0,
                block.timestamp,
                _purpose,
                Execution(to, callData)
            )
        );

        emit SectorAdded(id, _agendas[id].cNum - 1, _purpose);
    }

    /**
     *  @dev drop agenda
     *  @param agendaId drop target agenda id
     */
    function drop(
        uint agendaId
    )
        external
        virtual
        onlyExecutable(this.drop.selector)
        onlyValidator
        isNotBlackList(msg.sender)
    {
        uint id = agendaId;
        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);
        if (_agendas[agendaId].createdTime == 0)
            revert AgendaAlreadyDeleted(id);
        if (_agendas[agendaId].totalAmount != 0) revert AgendaStillHasVotes(id);

        // delete sector info & set sector dead
        delete _agendas[agendaId];

        emit AgendaDropped(agendaId);
    }

    /**
     *  @dev vote sector
     *  @param agendaId target agenda id
     *  @param user voting user
     *  @param idx sector index
     *  @param num voting num
     *  @param userSig user sig
     *  @param validatorSig validator sig
     */
    function vote(
        uint agendaId,
        address user,
        uint idx,
        uint num,
        bytes calldata userSig,
        bytes calldata validatorSig
    )
        external
        virtual
        onlyExecutable(this.vote.selector)
        isNotBlackList(msg.sender)
    {
        // to avoid stack too deep
        uint id = agendaId;
        address voteUser = user;
        uint index = idx;
        uint voteNum = num;

        (address recoveredUser, ) = _verifySignature(
            voteUser,
            abi.encodePacked(
                _getVerifyKey(voteUser, IGovernanceAccrue.vote.selector),
                id,
                voteUser,
                index,
                voteNum
            ),
            userSig,
            validatorSig
        );
        _renewSeed(recoveredUser);

        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);

        Agenda storage agenda = _agendas[id];

        if (index >= agenda.cNum) revert InvalidSectorIndex(index);
        if (voteNum < agenda.minVoteAmount)
            revert LessThanVoteLimit(agenda.minVoteAmount, voteNum);
        if (!agenda.sectors[index].isAlive) revert SectorNotAlive(index);

        UserInfo storage userInfo = userInfos[id][index][voteUser];
        Sector storage sector = agenda.sectors[index];

        unchecked {
            agenda.totalAmount += voteNum;
            sector.totalAmount += voteNum;
            userInfo.voteNum += voteNum;
        }

        sector.lastVoteTime = block.timestamp;
        userInfo.latestVoteTime = block.timestamp;

        token.safeTransferFrom(voteUser, treasury, voteNum);

        emit Voted(id, voteUser, index, voteNum);
    }

    /**
     *  @dev cancel vote from sector
     *  @param agendaId agenda id
     *  @param user voted user
     *  @param idx sector index
     *  @param num cancel num
     *  @param userSig user sig
     *  @param validatorSig validator sig
     */
    function cancel(
        uint agendaId,
        address user,
        uint idx,
        uint num,
        bytes calldata userSig,
        bytes calldata validatorSig
    )
        external
        virtual
        onlyExecutable(this.cancel.selector)
        isNotBlackList(msg.sender)
    {
        // to avoid stack too deep
        uint id = agendaId;
        uint index = idx;
        address cancelUser = user;
        uint cancelNum = num;

        (address recoveredUser, ) = _verifySignature(
            cancelUser,
            abi.encodePacked(
                _getVerifyKey(cancelUser, IGovernanceAccrue.cancel.selector),
                id,
                cancelUser,
                index,
                cancelNum
            ),
            userSig,
            validatorSig
        );
        _renewSeed(recoveredUser);

        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);

        Agenda storage agenda = _agendas[id];

        if (index >= agenda.cNum) revert InvalidSectorIndex(index);

        UserInfo storage userInfo = userInfos[id][index][cancelUser];

        if (block.timestamp < userInfo.latestVoteTime + agenda.coolTime)
            revert CoolTimeLock(
                block.timestamp,
                userInfo.latestVoteTime + agenda.coolTime
            );
        if (block.timestamp < userInfo.latestCancelTime + agenda.cancelLock)
            revert CancelLock(
                block.timestamp,
                userInfo.latestCancelTime + agenda.cancelLock
            );

        Sector storage sector = agenda.sectors[index];

        agenda.totalAmount -= cancelNum;
        sector.totalAmount -= cancelNum;
        sector.lastCancelTime = block.timestamp;
        userInfo.latestCancelTime = block.timestamp;

        userInfo.voteNum -= cancelNum;

        token.safeTransferFrom(treasury, cancelUser, cancelNum);
        emit Canceled(id, cancelUser, index, cancelNum);
    }

    /**
     *  @dev execute execution when sector is permited
     *  @param agendaId target agenda id
     *  @param idx sector index
     */
    function execute(
        uint agendaId,
        uint idx
    )
        external
        virtual
        nonReentrant
        onlyExecutable(this.execute.selector)
        onlyValidator
        isNotBlackList(msg.sender)
    {
        uint id = agendaId;
        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);

        _execute(agendaId, idx);
    }

    /**
     *  @dev change sector info by validator
     *  @param agendaId target agenda id
     *  @param idx sector index
     *  @param purpose new sector purpose
     *  @param to execution target contract address
     *  @param callData executing function calldata
     */
    function changeSector(
        uint agendaId,
        uint idx,
        bytes32 purpose,
        address to,
        bytes calldata callData
    )
        external
        virtual
        onlyExecutable(this.changeSector.selector)
        onlyValidator
        isNotBlackList(msg.sender)
    {
        uint index = idx;
        uint id = agendaId;
        bytes32 _purpose = purpose;

        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);
        if (_purpose == "") revert EmptyPurpose();

        Agenda storage agenda = _agendas[agendaId];

        if (index >= agenda.cNum) revert InvalidSectorIndex(index);

        Sector storage sector = agenda.sectors[idx];

        sector.purpose = purpose;
        sector.execution.to = to;
        sector.execution.callData = callData;

        emit ExecutionUpdated(agendaId, idx);
    }

    /**
     *  @dev change cooltime and cancelLock of agenda
     *  @param agendaId target agenda id
     *  @param newCoolTime new cancel cooltime
     *  @param newLockUp new cancel lock time
     */
    function changeOptions(
        uint agendaId,
        uint newCoolTime,
        uint newLockUp
    )
        external
        virtual
        onlyExecutable(this.changeOptions.selector)
        onlyValidator
        isNotBlackList(msg.sender)
    {
        uint id = agendaId;
        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);

        Agenda storage agenda = _agendas[agendaId];

        agenda.coolTime = newCoolTime;
        agenda.cancelLock = newLockUp;

        emit OptionsChanged(agendaId, newCoolTime, newLockUp);
    }

    /**
     * @dev change sector activation by validator
     * @param agendaId target agenda id
     * @param idx target sector idx
     */
    function changeSectorActivation(
        uint agendaId,
        uint idx
    )
        external
        virtual
        onlyExecutable(this.changeSectorActivation.selector)
        onlyValidator
        isNotBlackList(msg.sender)
    {
        uint id = agendaId;
        uint index = idx;
        if (!(id > 0 && id <= _agendaId.current())) revert InvalidAgendaId(id);

        Agenda storage agenda = _agendas[agendaId];
        if (!agenda.sectors[index].isAlive) revert SectorNotAlive(index);

        agenda.sectors[index].isAlive = false;

        emit ActivationChanged(agendaId, index, agenda.sectors[index].isAlive);
    }

    //===== VIEW FUNCTIONS =====//
    function getCurrentId() external view returns (uint) {
        return _agendaId.current();
    }

    function getAgenda(uint agendaId) external view returns (Agenda memory) {
        return _agendas[agendaId];
    }

    function getSector(
        uint agendaId,
        uint idx
    ) external view returns (Sector memory) {
        return _agendas[agendaId].sectors[idx];
    }

    function getAllVotes(
        uint agendaId
    ) external view returns (VoteInfo[] memory) {
        Agenda memory agenda = _agendas[agendaId];
        uint totalSectors = agenda.cNum;

        VoteInfo[] memory votes = new VoteInfo[](totalSectors);

        for (uint i = 0; i < totalSectors; i++) {
            votes[i] = VoteInfo({
                purpose: agenda.sectors[i].purpose,
                votes: agenda.sectors[i].totalAmount,
                voteTimes: agenda.sectors[i].lastVoteTime,
                cancelTimes: agenda.sectors[i].lastCancelTime
            });
        }

        return votes;
    }

    function getUserVotes(
        uint agendaId,
        address user
    ) external view returns (uint[] memory votes) {
        Agenda memory agenda = _agendas[agendaId];

        votes = new uint[](agenda.cNum);
        for (uint i = 0; i < agenda.cNum; i++) {
            votes[i] = userInfos[agendaId][i][user].voteNum;
        }
    }

    //===== INTERNAL FUNCTIONS =====//
    function _execute(uint agendaId, uint idx) internal virtual {
        uint index = idx;
        Agenda storage agenda = _agendas[agendaId];

        if (index >= agenda.cNum) revert InvalidSectorIndex(index);

        agenda.sectors[index].lastExecutionTime = block.timestamp;

        Execution memory targetExec = agenda.sectors[index].execution;

        if (!(targetExec.to != address(0) && targetExec.callData.length >= 4))
            revert InvalidExecution(index);

        (bool status, ) = targetExec.to.call(targetExec.callData);

        if (status) {
            emit ExecuteSuccess(agendaId, index, targetExec.to);
        } else {
            emit ExecuteFail(agendaId, index, targetExec.to);
        }
    }

    function _getValidatorRole()
        internal
        view
        virtual
        override
        returns (bytes32)
    {
        return validatorRole;
    }
}
