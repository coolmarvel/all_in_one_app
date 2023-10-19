const commander = require("commander");
const readline = require("readline");
const path = require("path");

const { options, commands } = require("./services/flags");

const major_version = 1;
const minor_version = 1;
const patch_version = 0;

const git_commit = "";
const app_version = `v${major_version}.${minor_version}.${patch_version}`;
if (git_commit.length >= 8) app_version += "-" + git_commit.slice(0, 8);

// Initialize the commander program
const program = new commander.Command();

program
  .name(path.basename(process.argv[0]))
  .version(app_version)
  .description("The command line interface for Secure Tx")
  .usage("[global options] command [command options] [arguments...]");

// Add global options here using program.option(...)
program
  .option(options.url.name, options.url.usage, options.url.value)
  .option(options.contract.name, options.contract.usage)
  .option(options.owner.name, options.owner.usage)
  .option(options.from.name, options.from.usage)
  .option(options.dataDir.name, options.dataDir.usage, options.dataDir.value)
  .option(options.output.name, options.output.usage)
  .option(options.threshold.name, options.threshold.usage, options.threshold.value)
  .option(options.config.name, options.config.usage, options.config.value)
  .option(options.chain.name, options.chain.usage, options.chain.value)
  .option(options.compile.name, options.compile.usage)
  .option(options.test.name, options.test.usage)
  .option(options.filter.name, options.filter.usage)
  .option(options.lock.name, options.lock.usage)
  .option(options.unlock.name, options.unlock.usage)
  .option(options.keyhash.name, options.keyhash.usage)
  .option(options.keystore.name, options.keystore.usage)
  .option(options.message.name, options.message.usage)
  .option(options.update.name, options.update.usage)
  .option(options.keytest.name, options.keytest.usage)
  .option(options.name.name, options.name.usage)
  .option(options.project.name, options.project.usage)
  .option(options.file.name, options.file.usage)
  .option(options.abstract.name, options.abstract.usage)
  .option(options.interface.name, options.interface.usage)
  .option(options.record.name, options.record.usage)
  .option(options.multi.name, options.multi.usage)
  .option(options.allow.name, options.allow.usage)
  .option(options.pack.name, options.pack.usage, options.pack.value)
  .option(options.ledger.name, options.ledger.usage)
  .option(options.payer.name, options.payer.usage);

// Add commands here using program.command(...)
program
  .command(commands.deploy.name)
  .description(commands.deploy.description)
  .option(options.from.name, options.from.usage)
  .option(options.project.name, options.project.usage)
  .option(options.keystore.name, options.keystore.usage)
  .option(options.threshold.name, options.threshold.usage, options.threshold.value)
  .action(async () => {
    const options = program.opts();

    const deploy = require("./services/deploy");

    await deploy(options);
  });

program
  .command(commands.genkey.name)
  .description(commands.genkey.description)
  .action(async () => {
    const { generateKeystore } = require("./services/keystore");

    await generateKeystore();
  });

program
  .command(commands.check.name)
  .description(commands.check.description)
  .option(options.from.name, options.from.usage)
  .option(options.keystore.name, options.keystore.usage)
  .option(options.threshold.name, options.threshold.usage, options.threshold.value)
  .action(async () => {
    const { unlockKeystore } = require("./services/keystore");

    const options = program.opts();

    let from = null;
    let threshold = 1;
    let keystore = null;

    if (options.from) from = options.from;
    if (options.keystore) keystore = options.keystore;
    if (options.threshold) threshold = parseInt(options.threshold);

    await unlockKeystore(from, keystore, threshold);
  });

program
  .command(commands.update.name)
  .description(commands.update.description)
  .option(options.from.name, options.from.usage)
  .option(options.keystore.name, options.keystore.usage)
  .option(options.threshold.name, options.threshold.usage, options.threshold.value)
  .action(async () => {
    const { updateKeystore } = require("./services/keystore");

    const options = program.opts();

    let from = null;
    let threshold = 1;
    let keystore = null;

    if (options.from) from = options.from;
    if (options.keystore) keystore = options.keystore;
    if (options.threshold) threshold = parseInt(options.threshold);

    await updateKeystore(from, keystore, threshold);
  });

program
  .command(commands.console.name)
  .description(commands.console.description)
  .option(options.from.name, options.from.usage)
  .option(options.allow.name, options.allow.usage)
  .option(options.unlock.name, options.unlock.usage)
  .option(options.keystore.name, options.keystore.usage)
  .option(options.config.name, options.config.usage, options.config.value)
  .option(options.dataDir.name, options.dataDir.usage, options.dataDir.value)
  .option(options.threshold.name, options.threshold.usage, options.threshold.value)
  .action(async () => {
    const compileSolidity = require("./services/compiler");

    const options = program.opts();

    const dir = path.join(__dirname, "contracts");
    const necessary = [
      path.join(dir, "Registry/Registry.sol"),
      path.join(dir, "openzeppelin-contracts/token/ERC20/ERC20.sol"),
      path.join(dir, "openzeppelin-contracts/token/ERC721/ERC721.sol"),
      path.join(dir, "openzeppelin-contracts/token/ERC1155/ERC1155.sol"),
    ];

    console.log("\nCompile Contracts...\n");
    const compiled = [];
    for (const sourceFile of necessary) {
      const data = await compileSolidity(sourceFile);
      compiled.push(data);
    }

    const { interactiveCLI, clearScreen } = require("./services/console");
    await clearScreen();
    await interactiveCLI(options, compiled);

    // const { clearScreen, app } = require("./services/console");
    // await clearScreen();
    // await app(options);
  });

program.command(commands.create.name).description(commands.create.description);
program.command(commands.gen.name).description(commands.gen.description);
program.command(commands.manager.name).description(commands.manager.description);
program.command(commands.send.name).description(commands.send.description);
program.command(commands.sign.name).description(commands.sign.description);
program.command(commands.transfercoin.name).description(commands.transfercoin.description);

if (!process.argv.slice(2).length) {
  program.outputHelp();
  process.exit();
}

// If the command is not recognized, output help and exit
program.on("command:*", function () {
  console.error("Invalid command: %s\nSee --help for a list of available commands.", program.args.join(" "));
  process.exit(1);
});

// Close stdin after running the program
process.on("exit", function () {
  readline.emitKeypressEvents(process.stdin);
  if (process.stdin.isTTY) process.stdin.setRawMode(false);
});

// Finally, parse the command line arguments and execute the corresponding command
program.parse(process.argv);
