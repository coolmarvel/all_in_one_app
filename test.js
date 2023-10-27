const fs = require("fs-extra");
const path = require("path");
const solc = require("solc");

const contractPath = path.resolve(__dirname, "contracts/Registry");
const fileNames = fs.readdirSync(contractPath);
console.log(`fileNames:: ${fileNames}`);

const compilerInput = {
  language: "Solidity",
  sources: fileNames.reduce((input, fileName) => {
    const filePath = path.resolve(contractPath, fileName);
    const source = fs.readFileSync(filePath, "utf8");

    return { ...input, [fileName]: { content: source } };
  }, {}),
  settings: { outputSelection: { "*": { "*": ["*"] } } },
};

const compiled = JSON.parse(solc.compile(JSON.stringify(compilerInput)));
console.log(compiled);

fileNames.map((fileName) => {
  const contracts = Object.keys(compiled.contracts[fileName]);
  contracts.map((contract) => {
    console.log(compiled.contracts[fileName][contract]);
  });
});
