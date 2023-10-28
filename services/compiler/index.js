const fs = require("fs");
const path = require("path");
const solc = require("solc");

const startDir = path.join(__dirname, "../../contracts");

const findSolFiles = (dir, fileList = []) => {
  let files = fs.readdirSync(dir);

  files.forEach(async (file) => {
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

// Define the findImports callback function
function findImports(importPath) {
  importPath = path.normalize(importPath);

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

module.exports = compileSolidity;
