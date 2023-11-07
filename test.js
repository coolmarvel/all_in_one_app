const Transport = require("@ledgerhq/hw-transport-node-hid").default;
const Eth = require("@ledgerhq/hw-app-eth").default;

const getProvider = require("./utils/provider");

const signTransactionByLedger = async () => {
  try {
    const transport = await Transport.create();
    const eth = new Eth(transport);

    const web3 = await getProvider();

    const hdPath = "m/44'/60'/0'/0/0";
    const address = (await eth.getAddress(hdPath)).address;
    console.log(`Ledger address: ${address}`);

    // console.log(eth);

    const tx = {};
    tx.from = address;
    tx.to = "0x5dc93ef0344a9d86fe6e172566a744e8e3078bf8";
    tx.value = web3.utils.toWei("0.1", "ether");
    tx.gas = "21000";
    tx.gasPrice = await web3.eth.getGasPrice();
    tx.nonce = await web3.eth.getTransactionCount(tx.from);
    tx.chainId = await web3.eth.getChainId();

    console.log(tx);

    const {ledgerService} = require("@ledgerhq/hw-app-eth");
    const Utils = require("ethereumjs-util");
    const RLP = Utils.rlp;

    const txRLP = RLP.encode([tx.chainId, tx.nonce, tx.from, tx.to, tx.value, tx.gas, tx.gasPrice]);
    const typeTxHex = "0x02" + Utils.bufferToHex(txRLP).slice(2);
    const txHash = Utils.bufferToHex(Utils.toBuffer(typeTxHex));

    const resolution = await ledgerService.resolveTransaction(txHash);
    console.log(resolution);

    const signedTx = await eth.signTransaction(hdPath, txHash, resolution);
    console.log(signedTx);
  } catch (error) {
    console.error(error.message);
  }
};
signTransactionByLedger();
