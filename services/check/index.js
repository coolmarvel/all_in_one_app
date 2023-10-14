const fs = require("fs");
const path = require("path");
const inquirer = require("inquirer");
const { unlockShares, privateKeyToAddress } = require("sss-pk-generator");

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

const askKeystoreDir = (split, index) => {
  const questions = [
    {
      type: "input",
      name: "keystoreDir",
      message: `Enter the path to store the unlock (${index}/${split}) : `,
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

const askStrictPassphrase = () => {
  const questions = [
    {
      type: "password",
      name: "password",
      message: `Enter the password Passphrase : `,
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

const unlockKeystore = async () => {
  try {
    const { split } = await askSplit();
    console.log(`splitN: ${split}`);

    const { threshold } = await askThreshold(split);
    console.log(`threshold: ${threshold}`);

    const secrets = [];
    const cipherparams = [];
    for (let i = 0; i < threshold; i++) {
      const { keystoreDir } = await askKeystoreDir(split, i + 1);

      let json;
      if (fs.lstatSync(keystoreDir).isDirectory()) {
        const files = fs.readdirSync(keystoreDir);
        for (const file of files) {
          const filePath = path.join(keystoreDir, file);
          if (path.extname(filePath) === ".json") json = JSON.parse(fs.readFileSync(filePath).toString());
        }
      } else if (fs.lstatSync(keystoreDir).isFile()) {
        json = JSON.parse(fs.readFileSync(keystoreDir).toString());
      }
      cipherparams.push(json.params);

      // passphrase input
      const { password } = await askStrictPassphrase();
      secrets.push(password);
    }

    const pk = unlockShares(secrets.map((s, idx) => ({ cipherparams: cipherparams[idx], secret: s })));
    console.log(`privateKey ${pk}`);

    const address = privateKeyToAddress(pk);
    console.log(`address ${address}`);
  } catch (error) {
    console.error(error.message);
  }
};
unlockKeystore();
