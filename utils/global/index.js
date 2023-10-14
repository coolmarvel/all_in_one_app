const fs = require("fs");
const toml = require("toml");

// TOML
const read = fs.readFileSync("config.toml", "utf-8");
const data = toml.parse(read);

const name = data.node.name;

const global = {};

global.name = name;

console.log(global);
