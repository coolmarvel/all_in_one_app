const fs = require("fs");
const path = require("path");
const solc = require("solc");

const getProvider = require("../../utils/provider");

const startDir = path.join(__dirname, "../../contracts");

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
  const solFiles = findSolFiles(startDir);

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
        data.contract = output.contracts[file.name][contract];
        data.abi = output.contracts[file.name][contract].abi;
        data.metadata = output.contracts[file.name][contract].metadata;
        data.bytecode = output.contracts[file.name][contract].evm.bytecode.object;
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

    const solFiles = findSolFiles(startDir);

    let deployFiles = [];
    solFiles.forEach((file) => {
      if (file.includes(`${options.project}.sol`)) deployFiles.push(file);
    });
    // console.log(deployFiles);

    const compiled = await compileSolidity(deployFiles[0]);
    console.log(compiled);
  } catch (error) {
    console.error(error.message);
  }
};

module.exports = deploy;
