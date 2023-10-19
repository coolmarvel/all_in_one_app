const Utils = require("ethereumjs-util");
const RLP = Utils.rlp;

const D_TxType = "0x02";
const FD_TxType = "0x16";

const unsignedTxDecode = (rawTransaction) => {
  return new Promise(async (resolve, reject) => {
    try {
      const decodeTx = {};
      const txType = rawTransaction.slice(0, 4);
      console.log("decodeRLP= ", txType);

      if (txType == D_TxType) {
        const [chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gas, to, value, data, [accessList]] = RLP.decode(
          Utils.toBuffer("0x" + rawTransaction.slice(4))
        );

        decodeTx.chainId = Utils.bufferToInt(chainId);
        decodeTx.nonce = Utils.bufferToInt(nonce);
        decodeTx.maxPriorityFeePerGas = Utils.bufferToHex(maxPriorityFeePerGas);
        decodeTx.maxFeePerGas = Utils.bufferToHex(maxFeePerGas);
        decodeTx.gas = Utils.bufferToHex(gas);
        decodeTx.to = Utils.bufferToHex(to);
        decodeTx.value = Utils.bufferToHex(value);
        decodeTx.input = Utils.bufferToHex(data);
        decodeTx.accessList = Utils.bufferToHex(accessList);
        if (decodeTx.accessList == "0x") decodeTx.accessList = [];
      } else if (txType == FD_TxType) {
        const [[chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gas, to, value, data, [accessList], v, r, s], feePayer] = RLP.decode(
          Utils.toBuffer("0x" + rawTransaction.slice(4))
        );
        decodeTx.chainId = Utils.bufferToInt(chainId);
        decodeTx.nonce = Utils.bufferToInt(nonce);
        decodeTx.maxPriorityFeePerGas = Utils.bufferToHex(maxPriorityFeePerGas);
        decodeTx.maxFeePerGas = Utils.bufferToHex(maxFeePerGas);
        decodeTx.gas = Utils.bufferToHex(gas);
        decodeTx.to = Utils.bufferToHex(to);
        decodeTx.value = Utils.bufferToHex(value);
        decodeTx.input = Utils.bufferToHex(data);
        decodeTx.accessList = Utils.bufferToHex(accessList);
        if (decodeTx.accessList == "0x") decodeTx.accessList = [];
        decodeTx.v = v;
        decodeTx.r = r;
        decodeTx.s = s;
        decodeTx.feePayer = Utils.bufferToHex(feePayer);
      }

      resolve(decodeTx);
    } catch (error) {
      return reject(error);
    }
  });
};

const signedTxDecode = (rawTransaction) => {
  return new Promise(async (resolve, reject) => {
    try {
      const decodeTx = {};
      const txType = rawTransaction.slice(0, 4);
      console.log("decodeRLP=", txType);
      if (txType == D_TxType) {
        const [chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gas, to, value, data, [accessList], v, r, s] = RLP.decode(
          Utils.toBuffer("0x" + rawTransaction.slice(4))
        );
        decodeTx.chainId = Utils.bufferToInt(chainId);
        decodeTx.nonce = Utils.bufferToInt(nonce);
        decodeTx.maxPriorityFeePerGas = Utils.bufferToHex(maxPriorityFeePerGas);
        decodeTx.maxFeePerGas = Utils.bufferToHex(maxFeePerGas);
        decodeTx.gas = Utils.bufferToHex(gas);
        decodeTx.to = Utils.bufferToHex(to);
        decodeTx.value = Utils.bufferToHex(value);
        decodeTx.input = Utils.bufferToHex(data);
        decodeTx.accessList = Utils.bufferToHex(accessList);
        if (decodeTx.accessList == "0x") decodeTx.accessList = [];
        decodeTx.v = v;
        decodeTx.r = r;
        decodeTx.s = s;
      } else if (txType == FD_TxType) {
        const [[chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gas, to, value, data, [accessList], v, r, s], feePayer, fv, fr, fs] = RLP.decode(
          Utils.toBuffer("0x" + rawTransaction.slice(4))
        );
        decodeTx.chainId = Utils.bufferToInt(chainId);
        decodeTx.nonce = Utils.bufferToInt(nonce);
        decodeTx.maxPriorityFeePerGas = Utils.bufferToHex(maxPriorityFeePerGas);
        decodeTx.maxFeePerGas = Utils.bufferToHex(maxFeePerGas);
        decodeTx.gas = Utils.bufferToHex(gas);
        decodeTx.to = Utils.bufferToHex(to);
        decodeTx.value = Utils.bufferToHex(value);
        decodeTx.input = Utils.bufferToHex(data);
        decodeTx.accessList = Utils.bufferToHex(accessList);
        if (decodeTx.accessList == "0x") decodeTx.accessList = [];
        decodeTx.v = v;
        decodeTx.r = r;
        decodeTx.s = s;
        decodeTx.feePayer = Utils.bufferToHex(feePayer);
        decodeTx.fv = fv;
        decodeTx.fr = fr;
        decodeTx.fs = fs;
      }

      resolve(decodeTx);
    } catch (error) {
      return reject(error);
    }
  });
};

module.exports = { unsignedTxDecode, signedTxDecode };
