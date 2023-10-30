// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGovernanceAccrue {
    //===== STRUCTS =====//
    struct Agenda {
        bytes32 purpose; // agenda purpose
        uint cNum; // num of sector
        uint totalAmount; // total agenda voted amount
        uint minVoteAmount; // user min vote amount
        uint createdTime; // agenda created time
        uint coolTime; // cancel vote cool time
        uint cancelLock; // lock up for next cancel
        Sector[] sectors; // agenda sectors
    }

    struct Sector {
        bool isAlive; // flag of sector that view sector is alive
        uint totalAmount; // total sector voted amount
        uint lastVoteTime; // last vote time stamp
        uint lastCancelTime; // last cancel time stamp
        uint lastExecutionTime; // last execution time
        bytes32 purpose; // sector purpose
        Execution execution; // execution info
    }

    struct Execution {
        address to; // execution target address
        bytes callData; // execute function calldata
    }

    struct UserInfo {
        uint voteNum; // vote amount per sector
        uint latestVoteTime; // latest vote time per sector
        uint latestCancelTime; // latest cancel time per sector
    }

    // only for return votes info
    struct VoteInfo {
        bytes32 purpose; // sector purpose
        uint votes; // total votes for each sectors
        uint voteTimes; // last vote times for each sectors
        uint cancelTimes; // last cancel times for each sectors
    }

    //===== FUNCTIONS =====//
    function vote(
        uint agendaId,
        address user,
        uint idx,
        uint num,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) external;

    function cancel(
        uint agendaId,
        address user,
        uint idx,
        uint num,
        bytes calldata userSig,
        bytes calldata validatorSig
    ) external;

    //===== EVENTS =====//
    event Created(
        uint indexed agendaId,
        bytes32 indexed purpose,
        uint createdTime
    );
    event SectorAdded(
        uint indexed agendaId,
        uint indexed idx,
        bytes32 indexed purpose
    );
    event ExecutionUpdated(uint indexed agendaId, uint indexed idx);
    event AgendaDropped(uint indexed agendaId);
    event ExecuteSuccess(
        uint indexed agendaId,
        uint indexed idx,
        address indexed to
    );
    event ExecuteFail(
        uint indexed agendaId,
        uint indexed idx,
        address indexed to
    );
    event Voted(
        uint indexed agendaId,
        address indexed user,
        uint indexed idx,
        uint num
    );
    event Canceled(
        uint indexed agendaId,
        address indexed user,
        uint indexed idx,
        uint num
    );
    event OptionsChanged(
        uint indexed agendaId,
        uint newCoolTime,
        uint newLockUp
    );
    event ActivationChanged(uint indexed agendaId, uint idx, bool activation);
    event ShutDown(address indexed to, uint indexed amount);

    //===== ERRORS =====//
    error InvalidAgendaId(uint id);
    error AgendaAlreadyDeleted(uint id);
    error AgendaStillHasVotes(uint id);
    error EmptyPurpose();
    error InvalidSectorIndex(uint index);
    error LessThanVoteLimit(uint limit, uint amount);
    error SectorNotAlive(uint index);
    error CoolTimeLock(uint timeStamp, uint unlockTime);
    error CancelLock(uint timeStamp, uint unlockTime);
    error InvalidExecution(uint index);
}
