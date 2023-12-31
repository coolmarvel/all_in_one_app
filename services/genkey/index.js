const fs = require("fs");
const inquirer = require("inquirer");
const { generateKey } = require("sss-pk-generator");

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
      message: `Enter the password of new account.\nⓥ 13 or more characters\nⓥ 1 or more special characters\nⓥ 1 or more big letters\nⓥ 1 or more digits\nPassphrase : `,
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

const jsonBuilder = async (address, params) => {
  const parsedParams = JSON.parse(params);

  return `{"address":"${address}","params":{"ct":"${parsedParams.ct}","iv":"${parsedParams.iv}","s":"${parsedParams.s}"}}`;
};

const generateKeystore = async () => {
  try {
    const { split } = await askSplit();
    console.log(`splitN: ${split}`);

    // 분할 없는 키 생성
    if (split === 1) {
      const { strict } = await askStrict();

      if (strict === "default") {
        const { password } = await askStrictPassphrase();
        const validatePassword = await askRepeatStrictPassphrase(password);
        if (validatePassword) {
          console.log("Passwords matched. Proceeding...");
        }
      }
    }
    // 분할 하는 키 생성
    else {
      const { threshold } = await askThreshold(split);
      console.log(`threshold: ${threshold}`);

      const secrets = [];
      for (let i = 1; i <= split; i++) {
        const { password } = await askStrictPassphrase();
        const validatePassword = await askRepeatStrictPassphrase(password);

        if (validatePassword) secrets.push(password);
      }

      const key = generateKey(secrets, threshold);
      const shares = key.shares;

      for (let i = 0; i < shares.length; i++) {
        // 키스토어 분할 경로 지정해주는 로직
        const { keystoreDir } = await askKeystoreDir(split, i + 1);

        const filename = `keystore-${i + 1}of${split}_${key.address}.json`;
        const shareFile = await jsonBuilder(key.address, shares[i].cipherparams);

        if (!fs.existsSync(`${keystoreDir}`)) fs.mkdirSync(`${keystoreDir}`);
        fs.writeFileSync(`${keystoreDir}/${filename}`, shareFile);
      }

      console.log(`Generate Success!!\nAddress: ${key.address}`);
    }
  } catch (error) {
    console.error(error.message);
  }
};
generateKeystore();
