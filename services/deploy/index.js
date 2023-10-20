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
    // console.log(deployFiles);

    const compiled = await compileSolidity(deployFiles[0]);

    const names = [];
    for (const key in compiled) {
      const name = key.replace(/\.sol/g, "");
      names.push(name);
    }

    const answers = await ask.askEnsureDeploy(names);
    const wallet = await unlockKeystore(options.keystore, options.threshold);
    for (const key in answers) {
      if (answers[key] === true) {
        const dynamicTx = await makeDynamicTx(web3, wallet.address, null, "0", compiled[`${key}.sol`].bytecode);

        console.log(`

     - ${key}
     - ContractRegistry already exist
     - type       : ${dynamicTx.type}
     - contract   : ${key}
     - chainID    : ${dynamicTx.chainId}
     - from       : ${dynamicTx.from}
     - to         : ${dynamicTx.to}
     - nonce      : ${dynamicTx.nonce}
     - gasFeeCap  : ${dynamicTx.maxPriorityFeePerGas}
     - gasTipCap  : ${dynamicTx.maxFeePerGas}
     - value      : ${dynamicTx.value}
     - gasLimit   : ${dynamicTx.gas}

     -> Deploy contract
  `);
      }
    }
  } catch (error) {
    console.error(error.message);
  }
};

module.exports = deploy;
