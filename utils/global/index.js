const fs = require("fs");
const toml = require("toml");

// TOML
const read = fs.readFileSync("config.toml", "utf-8");
const data = toml.parse(read);

console.log(data);
