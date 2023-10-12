import inquirer from "inquirer";

const Web3 = require("web3");
const web3 = new Web3();

const { generateKey } = require("sss-pk-generator");

const readline = require("readline");
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

const question = (question) => {
  return new Promise((resolve) => {
    rl.question(question, (answer) => resolve(answer));
  });
};

const askSplit = async () => {
  const string = "How many share of password? if less than 2, a normal password is generated. <splitN> : ";

  const split = parseInt(await question(string));

  if (isNaN(split)) return await askSplit();
  else return split;
};

const askStrict = async () => {
  const string = "Choose whether it is a plain password(p) or a strict password(default) : ";

  const strict = await question(string);

  if (strict === "") return "default";
  else if (strict === "p") return "plain";
};

const askStrictPassphrase = async () => {};

const generateKeystore = async () => {
  try {
    const split = await askSplit();
    console.log(split);

    if (split == 1) await askStrict();
  } catch (error) {
    console.error(error.message);
  } finally {
    rl.close();
  }
};
// generateKeystore();
