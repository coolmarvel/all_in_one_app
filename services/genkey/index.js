const Web3 = require("web3");
const web3 = new Web3();

const { generateKey } = require("sss-pk-generator");
// const path = require("path");

// const readline = require("readline");
// const readlineSync = require("readline-sync");
// const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

process.on("SIGINT", function () {
  console.log("\nI caught SIGINT signal.");
  process.exit();
});

process.on("SIGTERM", function () {
  console.log("\nI caught SIGTERM signal.");
  process.exit();
});

const readlineSync = require("readline-sync");
const readline = require("readline");
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

const { writeFileSync } = require("fs");
const { resolve } = require("path");
const { cwd } = require("process");

function jsonKeyStringBuilder(address, params) {
  return new Promise((resolve, reject) => {
    try {
      const json = JSON.parse(params);

      resolve(`{"address": "${address}", "params": { "ct": "${json.ct}", "iv": "${json.iv}", "s": "${json.s}"}}`);
    } catch (error) {
      return reject(error);
    }
  });
}

async function makeNodeJsonFile(path, text) {
  writeFileSync(path, text);
}

function question(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => resolve(answer));
  });
}

function askSegments() {
  return new Promise(async (resolve, reject) => {
    try {
      let split = "";
      split = parseInt(await question(`How many share of password? if less than 2, a normal password is generated. <splitN> : `));
      console.log(`splitN: ${split}`);

      let threshold = "";
      threshold = parseInt(await question(`Enter the threshold, must be less than or equal to 3. <threshold> : `));
      console.log(`threshold: ${threshold}`);

      resolve({ split, threshold });
    } catch (error) {
      return reject(error);
    }
  });
}

function askSecrets(split, threshold) {
  return new Promise((resolve, reject) => {
    const regexTester =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~])[A-Za-z\d!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~]{8,}$/;
    const regexMsg =
      "password must contain uppercase letters, special characters and numbers and must be at least 8 characters long.";

    console.log(`${threshold} of ${split} Key Generate Start`);
    console.log(`ⓥ least 8 characters long\nⓥ 1 or more special characters\nⓥ 1 or more big letters\nⓥ 1 or more digits`);
    try {
      const secrets = [];

      while (secrets.length < split) {
        let ans = "";
        // ans = readlineSync.question(`password #${secrets.length + 1}:`, { hideEchoBack: true, mask: "" });

        try {
          ans = readlineSync.question(`password #${secrets.length + 1}: `, { hideEchoBack: true, mask: "" });
        } catch (e) {
          if (e.signal === "SIGINT" || e.signal === "SIGTERM" || e.exitCode === -1073741510 || e.exitCode === 3221225786) {
            console.log("\nreadlineSync caught signal.");
            setTimeout(function () {
              process.kill(process.pid, "SIGINT");
            }, 0);
          } else {
            console.error(e);
            process.exit(1);
          }
        }

        if (regexTester.test(ans)) {
          let ans2 = "";
          // ans2 = readlineSync.question(`reinput password:`, { hideEchoBack: true, mask: "" });

          try {
            ans2 = readlineSync.question(`re-input #${secrets.length + 1}: `, { hideEchoBack: true, mask: "" });
          } catch (e) {
            if (e.signal === "SIGINT" || e.signal === "SIGTERM" || e.exitCode === -1073741510 || e.exitCode === 3221225786) {
              console.log("\nreadlineSync caught signal.");
              setTimeout(function () {
                process.kill(process.pid, "SIGINT");
              }, 0);
            } else {
              console.error(e);
              process.exit(1);
            }
          }

          if (ans == "exit") process.exit(1);

          if (ans === ans2) secrets.push(ans);
          else console.log("password not matched");
        } else {
          console.log(regexMsg);
        }
      }

      resolve(secrets);
    } catch (error) {
      return reject(error);
    }
  });
}

async function generateKeyStore(dir = "./") {
  const segments = await askSegments();
  const split = segments.split;
  const threshold = segments.threshold;

  const secrets = await askSecrets(split, threshold);
  const res = generateKey(secrets, threshold);

  let result = [];
  for (let i = 0; i < split; i++) {
    let filename = `keystore_${i + 1}of${split}_${res.address}.json`;

    let keystorePath = resolve(cwd(), dir, filename);

    let keystoreJson = await jsonKeyStringBuilder(res.address, res.shares[i].cipherparams);

    await makeNodeJsonFile(keystorePath, keystoreJson);

    result.push(keystorePath);
  }

  console.log(`Generation Success!! ${res.address}`);

  return { address: res.address, n: split, t: threshold, result };
}

generateKeyStore();
