const fs = require("fs");
const path = require("path");
const solc = require("solc");

const ask = require("../../utils/gatherAsk");
const logger = require("../../utils/console");
const getProvider = require("../../utils/provider");

const {unlockKeystore} = require("../keystore");
const {makeDynamicTx} = require("../transaction");

const importDir = path.join(__dirname, "../../contracts");
const projectDir = path.join(__dirname, "../../projects");

const findSolFiles = (dir, fileList = []) => {
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    let filePath = path.join(dir, file);
    let fileStat = fs.statSync(filePath);
    let baseName = path.basename(filePath);

    if (fileStat.isDirectory()) {
      fileList = findSolFiles(filePath, fileList);
    } else if (filePath.endsWith(".sol")) {
      fileList.push(filePath);
    }
  });

  return fileList;
};

const findInterfaceFiles = (dir, fileList = []) => {
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    let filePath = path.join(dir, file);
    let fileStat = fs.statSync(filePath);
    let baseName = path.basename(filePath);

    if (fileStat.isDirectory()) {
      fileList = findInterfaceFiles(filePath, fileList);
    } else if (filePath.endsWith(".sol") && baseName.startsWith("I")) {
      fileList.push(filePath);
    }
  });

  return fileList;
};

function findImports(importPath) {
  importPath = path.normalize(importPath);

  if (importPath.startsWith("I")) {
    const solFiles = findInterfaceFiles(projectDir);

    let matchedFile = solFiles.find((solFile) => solFile.includes(importPath));

    if (matchedFile) {
      let contents = fs.readFileSync(matchedFile, "utf8");

      return {contents};
    } else {
      console.log(`No file found that includes ${importPath}`);
      return null;
    }
  } else {
    const solFiles = findSolFiles(importDir);

    let matchedFile = solFiles.find((solFile) => solFile.includes(importPath));

    if (matchedFile) {
      let contents = fs.readFileSync(matchedFile, "utf8");

      return {contents};
    } else {
      console.log(`No file found that includes ${importPath}`);
      return null;
    }
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

      const input = {language: "Solidity", sources: {}, settings: {outputSelection: {"*": {"*": ["*"]}}}};
      input.sources[file.name] = {content: file.content};

      const output = JSON.parse(solc.compile(JSON.stringify(input), {import: findImports}));

      const data = {};
      for (const contract in output.contracts[file.name]) {
        // console.log(output.contracts[file.name][contract].evm.gasEstimates); // gasEstimates

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

    let deployFiles;
    solFiles.forEach((file) => {
      if (file.includes(`${options.project}.sol`)) deployFiles = file;
    });

    const compiled = await compileSolidity(deployFiles);

    const names = [];
    for (const key in compiled) {
      const name = key.replace(/\.sol/g, "");
      names.push(name);
    }

    const answers = await ask.askEnsureDeploy(names);
    const wallet = await unlockKeystore(options.keystore, options.threshold);
    const account = await web3.eth.accounts.privateKeyToAccount(wallet.privateKey);

    for (const key in answers) {
      if (answers[key] === true) {
        const abi = compiled[`${key}.sol`].abi;
        const bytecode = compiled[`${key}.sol`].bytecode;

        let gasLimit;
        const contract = new web3.eth.Contract(abi);
        const deployTx = contract.deploy({data: `0x${bytecode}`, arguments: []});
        gasLimit = await deployTx.estimateGas({from: account.address});

        const tx = {};
        tx.from = account.address;
        tx.nonce = await web3.eth.getTransactionCount(tx.from);
        tx.value = web3.utils.toWei("0", "ether");
        tx.data = `0x${bytecode}`;
        tx.gas = gasLimit;
        tx.maxPriorityFeePerGas = await web3.eth.getGasPrice();
        tx.chainId = await web3.eth.getChainId();

        const signedTx = await web3.eth.accounts.signTransaction(tx, account.privateKey);
        // console.log(signedTx);

        const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
        console.log(receipt);

        // console.log(`

        //  - ${key}
        //    - ContractRegistry already exist
        //    - type       : ${type}
        //    - contract   : ${key}
        //    - chainID    : ${chainId}
        //    - from       : ${from}
        //    - to         : ${to}
        //    - nonce      : ${nonce}
        //    - gasTipCap  : ${maxPriorityFeePerGas}
        //    - gasFeeCap  : ${maxFeePerGas}
        //    - value      : ${value}
        //    - gasLimit   : ${gas}

        //  -> Deploy contract
        //     `);
      }
    }
  } catch (error) {
    console.error(error.message);
  }
};

module.exports = deploy;
