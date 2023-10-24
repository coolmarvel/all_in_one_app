const fs = require("fs");
const path = require("path");
const solc = require("solc");
const Utils = require("ethereumjs-util");

const ask = require("../../utils/gatherAsk");
const getProvider = require("../../utils/provider");

const { unlockKeystore } = require("../keystore");
const { makeDynamicTx } = require("../transaction");

const importDir = path.join(__dirname, "../../contracts");
const projectDir = path.join(__dirname, "../../projects");

const findSolFiles = (dir, fileList = []) => {
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    let filePath = path.join(dir, file);
    let stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      fileList = findSolFiles(filePath, fileList);
    } else if (filePath.endsWith(".sol")) {
      fileList.push(filePath);
    }
  });

  return fileList;
};

function findImports(importPath) {
  const solFiles = findSolFiles(importDir);

  let matchedFile = solFiles.find((solFile) => solFile.includes(importPath));

  if (matchedFile) {
    let contents = fs.readFileSync(matchedFile, "utf8");
    return { contents };
  } else {
    console.log(`No file found that includes ${importPath}`);
    return null;
  }
}

const slurpFile = (sourceFile) => {
  return new Promise((resolve, reject) => {
    try {
      const name = path.basename(sourceFile, ".sol");
      const content = fs.readFileSync(sourceFile, "utf8");

      const data = {};
      data.name = `${name}.sol`;
      data.content = content.toString();

      resolve(data);
    } catch (error) {
      return reject(error);
    }
  });
};

const compileSolidity = (sourceFile) => {
  return new Promise(async (resolve, reject) => {
    try {
      const file = await slurpFile(sourceFile);

      const input = { language: "Solidity", sources: {}, settings: { outputSelection: { "*": { "*": ["*"] } } } };
      input.sources[file.name] = { content: file.content };

      const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));

      const data = {};
      for (const contract in output.contracts[file.name]) {
        // data.contract = output.contracts[file.name][contract];
        data[file.name] = {
          abi: output.contracts[file.name][contract].abi,
          metadata: output.contracts[file.name][contract].metadata,
          bytecode: output.contracts[file.name][contract].evm.bytecode.object,
        };
      }
      console.log(`sourceFile ${sourceFile}`);

      resolve(data);
    } catch (error) {
      return reject(error);
    }
  });
};

const deploy = async (options) => {
  try {
    const web3 = await getProvider();

    const solFiles = findSolFiles(projectDir);

    let deployFiles = [];
    solFiles.forEach((file) => {
      if (file.includes(`${options.project}.sol`)) deployFiles.push(file);
    });

    const compiled = await compileSolidity(deployFiles[0]);

    const names = [];
    for (const key in compiled) {
      const name = key.replace(/\.sol/g, "");
      names.push(name);
    }

    const answers = await ask.askEnsureDeploy(names);
    const wallet = await unlockKeystore(options.keystore, options.threshold);

    await web3.eth.accounts.wallet.add(wallet.privateKey);

    for (const key in answers) {
      if (answers[key] === true) {
        // const dynamicTx = await makeDynamicTx(web3, wallet.address, null, "0", compiled[`${key}.sol`].bytecode);

        const abi = compiled[`${key}.sol`].abi;
        const bytecode = compiled[`${key}.sol`].bytecode;

        let gasLimit, maxFeePerGas, maxPriorityFeePerGas;

        const contract = new web3.eth.Contract(abi);

        const deployTx = contract.deploy({ data: `0x${bytecode}` }).encodeABI();
        estimateGas = await web3.eth.estimateGas({ data: deployTx });
        console.log(`gasLimit ${gasLimit}`);

        const currentBlock = await web3.eth.getBlock("latest");

        maxFeePerGas = currentBlock.baseFeePerGas * 2;
        maxPriorityFeePerGas = web3.utils.toWei("2", "gwei");

        const dynamicTx = {};
        dynamicTx.from = wallet.address;
        dynamicTx.data = `0x${bytecode}`;
        dynamicTx.gas = gasLimit;
        dynamicTx.maxPriorityFeePerGas = maxPriorityFeePerGas;
        dynamicTx.maxFeePerGas = maxFeePerGas;
        dynamicTx.value = web3.utils.toWei("0", "ether");
        dynamicTx.nonce = await web3.eth.getTransactionCount(dynamicTx.from);
        dynamicTx.chainId = await web3.eth.getChainId();

        console.log(`

   - ${key}
     - ContractRegistry already exist
     - type       : ${dynamicTx.type}
     - contract   : ${key}
     - chainID    : ${dynamicTx.chainId}
     - from       : ${dynamicTx.from}
     - to         : ${dynamicTx.to}
     - nonce      : ${dynamicTx.nonce}
     - gasFeeCap  : ${maxPriorityFeePerGas}
     - gasTipCap  : ${maxFeePerGas}
     - value      : ${dynamicTx.value}
     - gasLimit   : ${dynamicTx.gas}

   -> Deploy contract
      `);

        // const signedTx = await web3.eth.accounts.signTransaction(dynamicTx, wallet.privateKey);

        // const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
        // console.log(receipt);
      }
    }

    await web3.eth.accounts.wallet.remove(wallet.address);
  } catch (error) {
    console.error(error.message);
  }
};

module.exports = deploy;
