const fs = require("fs");
const path = require("path");
const Web3 = require("web3");
const aes = require("aes-js");
const shamir = require("shamir");
const CryptoJS = require("crypto-js");

const ask = require("../../utils/gatherAsk");

const web3 = new Web3();

const randPassphrase = async (n) => {
  const runes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~!@#$%^&*()_+{}|[]";

  let result = "";
  for (let i = 0; i < n; i++) {
    result += runes.charAt(Math.floor(Math.random() * runes.length));
  }

  return result;
};

const constantBytes = (size) => Buffer.alloc(size, "a");

const encrypt = (share, password) => {
  return new Promise((resolve, reject) => {
    try {
      const hash = CryptoJS.SHA3(password, { outputLength: 256 });
      const wordArray = CryptoJS.lib.WordArray.create(hash.words.slice(0, 4));
      const keyBytes = new Uint8Array(
        wordArray.words
          .map((word) => [(word >>> 24) & 0xff, (word >>> 16) & 0xff, (word >>> 8) & 0xff, word & 0xff])
          .flat()
      );

      const aesCtr = new aes.ModeOfOperation.ctr(keyBytes);
      const ciphertextBytes = aesCtr.encrypt(share);

      resolve(ciphertextBytes);
    } catch (error) {
      return reject(error);
    }
  });
};

const generateAccount = () => {
  return new Promise(async (resolve, reject) => {
    try {
    } catch (error) {
      return reject(error);
    }
  });
};

const generateKeystore = async () => {
  try {
    const { split } = await ask.askSplit();
    console.log(`splitN: ${split}`);

    // 분할 없는 키 생성
    if (split === 1) {
      const { strict } = await ask.askStrict();

      if (strict === "default") {
        const { password } = await ask.askStrictPassphrase();
        const validatePassword = await ask.askRepeatStrictPassphrase(password);
        if (validatePassword) {
          console.log("Passwords matched. Proceeding...");
        }
      }
    }
    // 분할 있는 키 생성
    else {
      const { threshold } = await ask.askThreshold(split);
      console.log(`threshold: ${threshold}`);

      const passphrase = await randPassphrase(16); // 랜덤 패스워드 생성

      const encoder = new TextEncoder();
      const passphraseBytes = encoder.encode(passphrase); // 패스워드 16바이트로 인코딩

      let shares = shamir.split(constantBytes, split, threshold, passphraseBytes); // sss로 분할

      let keystoreDir = "";
      for (let i = 0; i < split; i++) {
        ({ keystoreDir } = await ask.askKeystoreDir(split, i + 1));
        console.log(
          "Enter the password of new account.\nⓥ 13 or more characters\nⓥ 1 or more special characters\nⓥ 1 or more big letters\nⓥ 1 or more digits\n"
        );
        if (!fs.existsSync(`${keystoreDir}`)) fs.mkdirSync(`${keystoreDir}`);

        const { password } = await ask.askStrictPassphrase();
        const validatePassword = await ask.askRepeatStrictPassphrase(password);

        if (validatePassword) {
          console.log("Passwords matched. Proceeding...");

          shares[i + 1] = await encrypt(shares[i + 1], password); // 분할된 패스워드를 유저의 비밀번호로 암호화
          const json = { Index: i + 1, Share: Buffer.from(shares[i + 1]).toString("base64") };

          if (!fs.existsSync(`${keystoreDir}/passphrase`)) fs.mkdirSync(`${keystoreDir}/passphrase`);
          fs.writeFileSync(`${keystoreDir}/passphrase/share.sss`, JSON.stringify(json));
        }
      }
      const wallet = web3.eth.accounts.create();

      await web3.eth.accounts.wallet.add(wallet.privateKey);
      const keystore = web3.eth.accounts.wallet.encrypt(passphrase);
      console.log(keystore);

      fs.writeFileSync(`${path.dirname(keystoreDir)}/keystore_${wallet.address}.json`, JSON.stringify(keystore[0]));
      await web3.eth.accounts.wallet.remove(wallet.privateKey);
    }
  } catch (error) {
    console.error(error.message);
  }
};
generateKeystore();
