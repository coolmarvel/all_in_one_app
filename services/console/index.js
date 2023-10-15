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
  clearScreen() {
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
  console(options) {
    const vorpal = require("vorpal")();

    console.log(options);

    vorpal.delimiter(">>").show();

    vorpal.command("deploy", "Deploy contract").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("call", "Call").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("pcall", "Call proxy").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("exec", "Execute").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("address", "Get contract address").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("write", "Write tx files").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("balance", "Get address coin balance").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("transfercoin", "Transfer wemix coin").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("eventlog", "Search event logs").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("compile", "Recompile contracts").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("readable").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("abi").action((args, callback) => {
      this.console.log("hi");
      callback();
    });
    vorpal.command("clear").action((args, callback) => {
      clearScreen();
      callback();
    });
  },
};
