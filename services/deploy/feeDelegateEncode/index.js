const Utils = require("ethereumjs-util");
const RLP = Utils.rlp;
const D_TxType = "0x02";
const FD_TxType = "0x16";

const fdUnsignedTxEncode = (tx) => {
  return new Promise(async (resolve, reject) => {
    try {
      const txRlp = RLP.encode([
        [tx.chainId, tx.nonce, tx.maxPriorityFeePerGas, tx.maxFeePerGas, tx.gas, tx.to, tx.value, tx.input, tx.accessList, tx.v, tx.r, tx.s],
        tx.feePayer,
      ]);

      const typeTxHex = FD_TxType + Utils.bufferToHex(txRlp).slice(2);
      const txHash = Utils.bufferToHex(Utils.keccak256(Utils.toBuffer(typeTxHex)));

      resolve([txHash, typeTxHex]);
    } catch (error) {
      return reject(error);
    }
  });
};

const fdSignedTxEncode = (tx) => {
  return new Promise(async (resolve, reject) => {
    try {
      const txRlp = RLP.encode([
        [tx.chainId, tx.nonce, tx.maxPriorityFeePerGas, tx.maxFeePerGas, tx.gas, tx.to, tx.value, tx.input, tx.accessList, tx.v, tx.r, tx.s],
        tx.feePayer,
        tx.fv,
        tx.fr,
        tx.fs,
      ]);

      const typeTxHex = FD_TxType + Utils.bufferToHex(txRlp).slice(2);
      const txHash = Utils.bufferToHex(Utils.keccak256(Utils.toBuffer(typeTxHex)));

      resolve([txHash, typeTxHex]);
    } catch (error) {
      return reject(error);
    }
  });
};

const dUnsignedTxEncode = (tx) => {
  return new Promise(async (resolve, reject) => {
    try {
      const txRlp = RLP.encode([tx.chainId, tx.nonce, tx.maxPriorityFeePerGas, tx.maxFeePerGas, tx.gas, tx.to, tx.value, tx.input, tx.accessList]);

      const typeTxHex = D_TxType + Utils.bufferToHex(txRlp).slice(2);
      const txHash = Utils.bufferToHex(Utils.keccak256(Utils.toBuffer(typeTxHex)));

      resolve([txHash, typeTxHex]);
    } catch (error) {
      return reject(error);
    }
  });
};

const dSignedTxEncode = (tx) => {
  return new Promise(async (resolve, reject) => {
    try {
      const txRlp = RLP.encode([
        tx.chainId,
        tx.nonce,
        tx.maxPriorityFeePerGas,
        tx.maxFeePerGas,
        tx.gas,
        tx.to,
        tx.value,
        tx.input,
        tx.accessList,
        tx.v,
        tx.r,
        tx.s,
      ]);

      const typeTxHex = D_TxType + Utils.bufferToHex(txRlp).slice(2);
      const txHash = Utils.bufferToHex(Utils.keccak256(Utils.toBuffer(typeTxHex)));

      resolve([txHash, typeTxHex]);
    } catch (error) {
      return reject(error);
    }
  });
};

module.exports = { fdSignedTxEncode, fdUnsignedTxEncode, dUnsignedTxEncode, dSignedTxEncode };
