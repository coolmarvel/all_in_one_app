const { replOptions, replCommands, replHowToUse } = require("../flags");

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
    console.log(replHowToUse);
    vorpal.delimiter(">>").show();

    // console.log(options);

    vorpal
      .command(replCommands.deploy.name, replCommands.deploy.description)
      // .option()
      .action(async (args, callback) => {
        console.log("hi");
        console.log(args);
        await callback();
      });
    vorpal.command(replCommands.call.name, replCommands.call.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.pcall.name, replCommands.pcall.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.exec.name, replCommands.exec.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.pexec.name, replCommands.pexec.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.address.name, replCommands.address.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.write.name, replCommands.write.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.balance.name, replCommands.balance.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.transfercoin.name, replCommands.transfercoin.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.eventlog.name, replCommands.eventlog.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.compile.name, replCommands.compile.description).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.readable.name).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.abi.name).action((args, callback) => {
      console.log("hi");
      callback();
    });
    vorpal.command(replCommands.clear.name).action((args, callback) => {
      clearScreen();
      callback();
    });
  },
};
