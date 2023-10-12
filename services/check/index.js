const { privateKeyToAddress, unlockShares } = require("sss-pk-generator");
const { existsSync, readFileSync } = require("fs");
const readlineSync = require("readline-sync");

function unlockKeyStore(options) {
  const secrets = [];
  const cipherparams = [];
  let threshhold = askThreshhold();

  while (threshhold) {
    let ans = "";
    let json;

    ans = readlineSync.question(`[${secrets.length + 1}] input path of key store json(or ENTER to exit): `);
    ans = (ans || "").trim();

    if (ans === "") {
      console.log("end of shares");
      break;
    } else if (existsSync(ans)) {
      json = JSON.parse(readFileSync(ans).toString());

      if (json?.address && json?.params?.ct && json?.params?.iv && json?.params?.s) {
        let passphrase = readlineSync.question("input the passphrase: ", { hideEchoBack: true, mask: "" });

        passphrase = (passphrase || "").trim();
        console.log(passphrase);

        cipherparams.push(json.params);
        secrets.push(passphrase);

        console.log("\n");
      } else {
        console.log("@ERR: not valid key store structrue");
      }
    } else {
      threshhold++;

      console.log("@ERR: not valid path");
    }

    threshhold--;
  }

  function askThreshhold() {
    const T = readlineSync.question("input treshhold: ");

    return T >= 2 ? T : askThreshhold();
  }

  console.log("\n the number of shares you filled: ", secrets.length);

  console.log(secrets);
  console.log(cipherparams);

  try {
    const pk = unlockShares(secrets.map((s, idx) => ({ cipherparams: cipherparams[idx], secret: s })));

    if (options.hidePk === false) console.log("\n(just for checking) private key => ", pk);

    const address = privateKeyToAddress(pk);

    console.log("and the address for the pk is ", privateKeyToAddress(pk), "\n[finished]\n\n");

    return { address, pk };
  } catch {
    console.log("The password is incorrect.");

    return null;
  }
}

unlockKeyStore();
