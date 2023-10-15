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

const decrypt = (ciphertextBytes, password) => {
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
      const share = aesCtr.decrypt(ciphertextBytes);

      resolve(share);
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

          const { keystoreDir } = await ask.askKeystoreDir();

          const wallet = web3.eth.accounts.create();

          await web3.eth.accounts.wallet.add(wallet.privateKey);
          const keystore = web3.eth.accounts.wallet.encrypt(password);

          fs.writeFileSync(`${keystoreDir}/keystore_${wallet.address}.json`, JSON.stringify(keystore[0]));
          await web3.eth.accounts.wallet.remove(wallet.privateKey);

          console.log(`Generate Success!\nAddress: ${wallet.address}\nPrivateKey: ${wallet.privateKey}`);
        }
      } else if (strict === "p") {
        const { password } = await ask.askPlainPassphrase();
        const validatePassword = await ask.askRepeatPlainPassphrase(password);

        if (validatePassword) {
          console.log("Password matched. Proceeding...");

          const { keystoreDir } = await ask.askKeystoreDir();

          const wallet = web3.eth.accounts.create();

          await web3.eth.accounts.wallet.add(wallet.privateKey);
          const keystore = web3.eth.accounts.wallet.encrypt(password);

          fs.writeFileSync(`${keystoreDir}/keystore_${wallet.address}.json`, JSON.stringify(keystore[0]));
          await web3.eth.accounts.wallet.remove(wallet.privateKey);

          console.log(`Generate Success!\nAddress: ${wallet.address}\nPrivateKey: ${wallet.privateKey}`);
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
        ({ keystoreDir } = await ask.askKeystoreSplitDir(split, i + 1));
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

      fs.writeFileSync(`${path.dirname(keystoreDir)}/keystore_${wallet.address}.json`, JSON.stringify(keystore[0]));
      await web3.eth.accounts.wallet.remove(wallet.privateKey);

      console.log(`Generate Success!\nAddress: ${wallet.address}\nPrivateKey: ${wallet.privateKey}`);
    }
  } catch (error) {
    console.error(error.message);
  }
};

const unlockKeystore = async (from, keystore, threshold) => {
  try {
    const stats = fs.statSync(keystore);

    let keystoreData;
    if (stats.isDirectory()) {
      const files = fs.readdirSync(inputPath);
      for (let file of files) {
        keystoreData = JSON.parse(fs.readFileSync(path.join(keystore, file), "utf8").toString());
      }
    } else if (stats.isFile()) {
      keystoreData = JSON.parse(fs.readFileSync(keystore).toString());
    } else {
      return new Error(`${keystore} is neither a directory nor a file.`);
    }

    if (!web3.utils.isAddress(keystoreData.address)) return new Error("Invalid address at keystore");
    if (from !== null && !web3.utils.isAddress(from)) return new Error("Invalid address at from");

    const keystoreAddress = web3.utils.toChecksumAddress(keystoreData.address);
    const fromAddress = web3.utils.toChecksumAddress(from);

    if (!web3.utils.checkAddressChecksum(keystoreAddress)) return new Error("Invalid BIP39 checksum at keystore");
    if (!web3.utils.checkAddressChecksum(fromAddress)) return new Error("Invalid BIP39 checksum at from");

    if (threshold === 1) {
      const { password } = await ask.askStrictPassphrase();

      const wallet = await web3.eth.accounts.wallet.decrypt([keystoreData], password);

      if (wallet) console.log(`Unlock success!\nAddress: ${wallet[0].address}`);
    } else if (threshold > 1) {
      if (keystoreAddress === fromAddress) {
        const shares = {};
        for (let i = 0; i < threshold; i++) {
          const { keystoreDir } = await ask.askKeystoreCombineDir(threshold, i + 1);

          if (!fs.existsSync(`${keystoreDir}/passphrase`)) return new Error("Non exist passphrase directory");

          const sssFile = JSON.parse(fs.readFileSync(`${keystoreDir}/passphrase/share.sss`, "utf8"));
          const ciphertextBytes = Uint8Array.from(Buffer.from(sssFile.Share, "base64"));

          const { password } = await ask.askStrictPassphrase();

          const share = await decrypt(ciphertextBytes, password);
          shares[i + 1] = share;
        }

        const originBytes = shamir.join(shares);

        const decoder = new TextDecoder();
        const origin = decoder.decode(originBytes);

        const wallet = await web3.eth.accounts.wallet.decrypt([keystoreData], origin);

        if (wallet) console.log(`Unlock success!\nAddress: ${wallet[0].address}`);
      }
    }
  } catch (error) {
    console.error(error.message);
    if (error.message.includes("possibly wrong password")) await unlockKeystore(from, keystore, threshold);
  }
};

module.exports = { generateKeystore, unlockKeystore };
