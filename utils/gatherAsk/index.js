const inquirer = require("inquirer");
const fs = require("fs");

// 키 분할을 얼만큼 할지 선택하는 로직
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

// 분할 된 키의 임계점을 선택하는 로직
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

// 규격화된 패스워드 설정을 할 지 선택하는 로직
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

// 규격화된 패스워드 입력하는 로직
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

// 규격화된 패스워드 확인하는 로직
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

// 약한 패스워드 입력하는 로직
const askPlainPassphrase = () => {
  const question = [
    {
      type: "password",
      name: "password",
      message: "Passphrase : ",
      validate: (value) => {
        const valid = value.length > 0;
        return valid || "Password does not meet the requirements";
      },
    },
  ];
  const passphrase = inquirer.prompt(question);

  return passphrase;
};

// 약한 패스워드 확인하는 로직
const askRepeatPlainPassphrase = (password) => {
  const question = [
    {
      type: "password",
      name: "password",
      message: "Repeat Passphrase : ",
      validate: function (value) {
        return value === password || "Passwords do not match";
      },
    },
  ];
  const passphrase = inquirer.prompt(question);

  return passphrase;
};

// 키스토어 저장 위치 입력하는 로직
const askKeystoreDir = () => {
  const questions = [
    {
      type: "input",
      name: "keystoreDir",
      message: `Enter the path to store : `,
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

// 분할 키스토어 저장 위치 입력하는 위치
const askKeystoreSplitDir = (split, index) => {
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

// 분할된 키스토어 저장된 위치 입력하는 로직
const askKeystoreCombineDir = (split, index) => {
  const questions = [
    {
      type: "input",
      name: "keystoreDir",
      message: `Enter the path to Retrieve the share (${index}/${split}) : `,
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

const askEnsureDeploy = (names) => {
  const questions = [];
  for (const name of names) {
    const question = { type: "confirm", name: `${name}`, message: `Are you sure to deploy ${name} tx?`, default: true };
    questions.push(question);
  }

  const answers = inquirer.prompt(questions);

  return answers;
};

module.exports = {
  askSplit,
  askStrict,
  askThreshold,
  askKeystoreDir,
  askKeystoreSplitDir,
  askKeystoreCombineDir,
  askStrictPassphrase,
  askRepeatStrictPassphrase,
  askPlainPassphrase,
  askRepeatPlainPassphrase,
  askEnsureDeploy,
};
