const Transport = require("@ledgerhq/hw-transport-node-hid").default;
const Eth = require("@ledgerhq/hw-app-eth").default;

const getProvider = require("./utils/provider");

const signTransactionByLedger = async () => {
  try {
    // const transport = await Transport.create();
    // const eth = await Eth(transport);

    const web3 = await getProvider();

    // const hdPath = "m/44'/60'/0'/0/0";
    // const result = await eth.getAddress(hdPath);
    // console.log(`Ledger address: ${result.address}`);

    const txObject = {};
    txObject.from = "5dc93ef0344a9d86fe6e172566a744e8e3078bf8";
    // txObject.from = result.address;
    txObject.to = "eafcd375e7868a351c1f24644cd435461dbf5945";
    txObject.value = web3.utils.toWei("0.1", "ether");
    txObject.gas = "21000";
    txObject.gasPrice = await web3.eth.getGasPrice();
    txObject.nonce = await web3.eth.getTransactionCount(txObject.from);
    txObject.chainId = web3.utils.toHex(await web3.eth.getChainId());

    const signedTx = await web3.eth.signTransaction(txObject);
    console.log(signedTx);

    // const signedTx = await eth.signTransaction(hdPath);
  } catch (error) {
    console.error(error.message);
  }
};
signTransactionByLedger();
