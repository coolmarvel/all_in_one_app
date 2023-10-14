const inquirer = require("inquirer");
const fs = require("fs");

const askSplit = () => {
  const questions = [
    {
      type: "input",
      name: "split",
      message: "How many share of password? if less than 2, a normal password is generated. <splitN> : ",
      validate: function (value) {
        const valid = !isNaN(parseFloat(value)) && parseFloat(value) < 10;
        return valid || "Please enter a number less than 10";
      },
      filter: Number,
    },
  ];
  const split = inquirer.prompt(questions);

  return split;
};

const askThreshold = (split) => {
  const question = [
    {
      type: "input",
      name: "threshold",
      message: `Enter the threshold, must be less than or equal to ${split}. <threshold> : `,
      validate: function (value) {
        const valid = !isNaN(parseFloat(value));
        return valid || "Please enter a number";
      },
      filter: Number,
    },
  ];
  const threshold = inquirer.prompt(question);

  return threshold;
};

const askStrict = () => {
  const questions = [
    {
      type: "list",
      name: "strict",
      message: "Choose whether it is a plain password(p) or a strict password(default) : ",
      choices: ["default", "p"],
    },
  ];
  const strict = inquirer.prompt(questions);

  return strict;
};

const askStrictPassphrase = () => {
  const questions = [
    {
      type: "password",
      name: "password",
      message: `Passphrase : `,
      validate: function (value) {
        const valid = value.length >= 13 && /[\W]/.test(value) && /[A-Z]/.test(value) && /[0-9]/.test(value);
        return valid || "Password does not meet the requirements";
      },
      // mask: "*",
    },
  ];
  const passphrase = inquirer.prompt(questions);

  return passphrase;
};

const askRepeatStrictPassphrase = (password) => {
  const questions = [
    {
      type: "password",
      name: "password",
      message: `Repeat Passphrase : `,
      validate: function (value) {
        return value === password || "Passwords do not match";
      },
      // mask: "*",
    },
  ];

  return inquirer.prompt(questions);
};

const askKeystoreDir = (split, index) => {
  const questions = [
    {
      type: "input",
      name: "keystoreDir",
      message: `Enter the path to store the share (${index}/${split}) : `,
      validate: function (value) {
        if (fs.existsSync(value)) {
          return true;
        } else {
          return "Directory does not exist. Please enter a valid path.";
        }
      },
    },
  ];

  return inquirer.prompt(questions);
};

module.exports = { askSplit, askStrict, askThreshold, askKeystoreDir, askStrictPassphrase, askRepeatStrictPassphrase };
