const Web3 = require("web3");

const global = require("../global");

const getProvider = () => {
  return new Promise(async (resolve, reject) => {
    try {
      const url = global.url;
      const web3 = new Web3(new Web3.providers.HttpProvider(url));

      resolve(web3);
    } catch (error) {
      return reject(error);
    }
  });
};

module.exports = getProvider;
