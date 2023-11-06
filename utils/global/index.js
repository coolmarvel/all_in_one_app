const fs = require("fs");
const toml = require("toml");

// TOML
const read = fs.readFileSync("config.toml", "utf-8");
const data = toml.parse(read);

const name = data.node.name;
const owner = data.keystore.owner;
const fee_payer = data.node.feepayer;
const mainnet_url = data.node.mainnet_url;
const testnet_url = data.node.testnet_url;

const multiSig_owner1 = data.roles.MultiSigWallet_Owner1.address;
const multiSig_owner2 = data.roles.MultiSigWallet_Owner2.address;
const multiSig_owner3 = data.roles.MultiSigWallet_Owner3.address;

const global = {};

global.name = name;
global.owner = owner;
global.fee_payer = fee_payer;
if (name === "mainnet") global.url = mainnet_url;
else if (name === "testnet") global.url = testnet_url;

global.multiSig_owner1 = multiSig_owner1;
global.multiSig_owner2 = multiSig_owner2;
global.multiSig_owner3 = multiSig_owner3;

module.exports = global;
