const global = require("../../utils/global");

const { dUnsignedTxEncode } = require("./feeDelegateEncode");

const makeLegacyTx = (web3, from, to, value, input) => {
  return new Promise(async (resolve, reject) => {
    try {
      const block = await web3.eth.getBlock();
      const baseFeePerGas = block.baseFeePerGas;
      const chainId = await web3.eth.getChainId();

      const legacyTx = {};
      legacyTx.from = from;
      legacyTx.chainId = chainId;
      legacyTx.nonce = nonce;
      legacyTx.gas = 100000000;
      legacyTx.to = to;
      legacyTx.value = "0x0";
      legacyTx.input = "0x";
      legacyTx.v = "0x0";
      legacyTx.r = "0x0";
      legacyTx.s = "0x0";
      legacyTx.accessList = [];

      resolve(legacyTx);
    } catch (error) {
      return reject(error);
    }
  });
};

const makeDynamicTx = (web3, from, to, value, input) => {
  return new Promise(async (resolve, reject) => {
    try {
      const chainId = await web3.eth.getChainId();
      const block = await web3.eth.getBlock("latest");
      const baseFeePerGas = block.baseFeePerGas;

      const maxPriorityFeePerGas = 200000000000;
      const maxFeePerGas = baseFeePerGas + maxPriorityFeePerGas;

      const nonce = await web3.eth.getTransactionCount(from);

      const dynamicTx = {};
      dynamicTx.from = from;
      dynamicTx.chainId = chainId;
      dynamicTx.nonce = nonce;
      dynamicTx.gas = "10000000";
      dynamicTx.maxFeePerGas = maxFeePerGas;
      dynamicTx.maxPriorityFeePerGas = maxPriorityFeePerGas;
      dynamicTx.to = to;
      dynamicTx.value = web3.utils.toWei(value, "ether");
      dynamicTx.input = input;
      dynamicTx.v = "0x0";
      dynamicTx.r = "0x0";
      dynamicTx.s = "0x0";
      dynamicTx.accessList = [];

      const hash = await dUnsignedTxEncode(dynamicTx);
      dynamicTx.hash = hash[0];
      dynamicTx.type = hash[1].slice(0, 4);

      resolve(dynamicTx);
    } catch (error) {
      return reject(error);
    }
  });
};

module.exports = { makeLegacyTx, makeDynamicTx };
