function clearScreen() {
  const osType = process.platform;
  let command;

  switch (osType) {
    case "win32":
      command = "\x1Bc";
      break;
    default:
      command = "\x1B[2J\x1B[0;0f";
  }

  process.stdout.write(command);
}

module.exports = {
  async clearScreen() {
    const osType = process.platform;
    let command;

    switch (osType) {
      case "win32":
        command = "\x1Bc";
        break;
      default:
        command = "\x1B[2J\x1B[0;0f";
    }

    process.stdout.write(command);
  },
  async app(options, compiled) {
    const vorpal = require("vorpal")();

    console.log(`
How to use:\n
  deploy <contract name> <params>
  address <contract name>
  call <contract name> <method> <params>
  pcall <proxy name> <logic name> <method> <params>
  exec <contract name> <method> <params>
  exec <address> <contract name> <method> <params>
  pexec <proxy name> <logic name> <method> <params>
  eventlog <contract name> <event name>
  eventlog <address> <logic name> <event name>
  balance <address>
  transfercoin <address>
  readable <hex>
  calldata <contract name> <method> <params>
  compile
  clear
  write
  abi\n`);

    vorpal.delimiter(">>").show();

    vorpal.command("deploy", "Deploy contract").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("call", "Call").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("pcall", "Call proxy").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("exec", "Execute").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("address", "Get contract address").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("write", "Write tx files").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("balance", "Get address coin balance").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("transfercoin", "Transfer wemix coin").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("eventlog", "Search event logs").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("compile", "Recompile contracts").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("readable").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("abi").action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command("clear").action((args, callback) => {
      clearScreen();
      callback();
    });
  },
};
