const { split, join } = require("shamir");
const CryptoJS = require("crypto-js");
const aesjs = require("aes-js");
const fs = require("fs");

const PARTS = 3;
const QUORUM = 2;
const password = "Thanksgod!@#456";

function randPassphrase(n) {
  var runes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~!@#$%^&*()_+{}|[]";
  var result = "";
  for (var i = 0; i < n; i++) {
    result += runes.charAt(Math.floor(Math.random() * runes.length));
  }
  return result;
}

function constantRandomBytes(size) {
  return Buffer.alloc(size, "a"); // replace 'a' with the byte you want
}

function doIt() {
  const secret = randPassphrase(16);
  console.log(secret);

  const utf8Encoder = new TextEncoder();
  const utf8Decoder = new TextDecoder();
  const secretBytes = utf8Encoder.encode(secret);

  // parts is a object whos keys are the part number and values are an Uint8Array
  let shares = split(constantRandomBytes, PARTS, QUORUM, secretBytes);
  console.log("origin shares");
  console.log(shares);

  console.log("encode shares");
  for (let i = 0; i < PARTS; i++) {
    let share = shares[i + 1];

    let hash = CryptoJS.SHA3(password, { outputLength: 256 });
    let keyWordArray = CryptoJS.lib.WordArray.create(hash.words.slice(0, share.length / 4));
    let keyUint8Array = new Uint8Array(
      keyWordArray.words
        .map((word) => [(word >>> 24) & 0xff, (word >>> 16) & 0xff, (word >>> 8) & 0xff, word & 0xff])
        .flat()
    );

    // Encrypt p.Share using AES
    let aesCtr = new aesjs.ModeOfOperation.ctr(keyUint8Array);
    let ciphertextBytes = aesCtr.encrypt(share);

    shares[i + 1] = ciphertextBytes;
    console.log(ciphertextBytes);

    let result = { Index: i + 1, Share: Buffer.from(shares[i + 1]).toString("base64") };
    console.log(result);

    const keystoreDir = "/Users/iseonghyeon/Desktop/waffle_js/keystore/klaytn";
    const filename = "share.sss";
    fs.writeFileSync(`${keystoreDir}/${i + 1}/${filename}`, JSON.stringify(result));
  }

  // we only need QUORUM of the parts to recover the secret
  delete shares[2];

  // recovered is an Unit8Array
  const recovered = join(shares);

  // prints 'hello there'
  console.log(utf8Decoder.decode(recovered)); // KO����x�t�ԝ�*u
}
doIt();

let shares = {};
function unlockpassphrase() {
  const keystoreDir = "/Users/iseonghyeon/Desktop/waffle_js/keystore/klaytn";
  const filename = "share.sss";

  for (let i = 0; i < QUORUM; i++) {
    let file = fs.readFileSync(`${keystoreDir}/${i + 1}/${filename}`, "utf8").toString();
    file = JSON.parse(file);

    const decode = Uint8Array.from(Buffer.from(file.Share, "base64"));

    let hash = CryptoJS.SHA3(password, { outputLength: 256 });
    let keyWordArray = CryptoJS.lib.WordArray.create(hash.words.slice(0, 16 / 4));
    let keyUint8Array = new Uint8Array(
      keyWordArray.words
        .map((word) => [(word >>> 24) & 0xff, (word >>> 16) & 0xff, (word >>> 8) & 0xff, word & 0xff])
        .flat()
    );

    // Encrypt p.Share using AES
    let aesCtr = new aesjs.ModeOfOperation.ctr(keyUint8Array);
    let ciphertextBytes = aesCtr.encrypt(decode);
    shares[i + 1] = ciphertextBytes;
  }

  // recovered is an Unit8Array
  const recovered = join(shares);

  const utf8Decoder = new TextDecoder();
  // prints 'hello there'
  console.log(utf8Decoder.decode(recovered));
}
// unlockpassphrase();
