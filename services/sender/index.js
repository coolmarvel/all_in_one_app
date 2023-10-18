const global = require("../../utils/global");

const isFeeDelegate = () => {
  return new Promise(async (resolve, reject) => {
    try {
      if (global.fee_payer === "0x0000000000000000000000000000000000000000") resolve(false);
      else resolve(true);
    } catch (error) {
      return reject(error);
    }
  });
};

const getNonce = (web3, address) => {
  return new Promise(async (resolve, reject) => {
    try {
      const nonce = await web3.eth.getTransactionCount(address, "pending");

      resolve(nonce);
    } catch (error) {
      return reject(error);
    }
  });
};

const getBalance = (web3, address) => {
  return new Promise(async (resolve, reject) => {
    try {
      const balanceWei = await web3.eth.getBalance(address);
      const balanceEth = web3.utils.fromWei(balanceWei);

      resolve({ balanceWei, balanceEth });
    } catch (error) {
      return reject(error);
    }
  });
};

module.exports = { getNonce, getBalance, isFeeDelegate };
