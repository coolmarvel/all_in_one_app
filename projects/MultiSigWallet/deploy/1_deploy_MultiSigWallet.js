const global = require("../../../utils/global");

const deployMultiSigWallet = async (params) => {
  try {
    const web3 = params.web3;

    const abi = params.abi;
    const account = params.account;
    const bytecode = params.bytecode;

    const quorum = 2;
    const owners = [global.multiSig_owner1, global.multiSig_owner2, global.multiSig_owner3];

    const contract = new web3.eth.Contract(abi);
    const deployTx = contract.deploy({data: `0x${bytecode}`, arguments: [owners, quorum]});
    const gasLimit = await deployTx.estimatesGas({from: account.address});

    const block = await web3.eth.getBlock("latest");
    const baseFeePerGas = block.baseFeePerGas;

    const tx = {};
    tx.from = account.address;
    tx.nonce = await web3.eth.getTransactionCount(account.address);
    tx.value = web3.utils.toWei("0", "ether");
    tx.data = `0x${bytecode}`;
    tx.gas = gasLimit;
    tx.maxPriorityFeePerGas = web3.utils.toWei("100.000000001", "gwei");
    tx.maxFeePerGas = web3.utils.toBN(baseFeePerGas).add(web3.utils.toBN(tx.maxPriorityFeePerGas));
    tx.chainId = await web3.eth.getChainId();
  } catch (error) {
    console.error(error.message);
  }
};

module.exports = deployMultiSigWallet;
