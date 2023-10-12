const commander = require("commander");
const readline = require("readline");
const path = require("path");

const major_version = 1;
const minor_version = 0;
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
  .option("--url <value>", "node url", "https://api.test.wemix.com/")
  .option("--contract <value>", "root directory for contracts source code to compile")
  .option("--owner <value>", "owner address")
  .option("--from <value>", "tx sender")
  .option("--datadir <value>", "the location where raw txs", "./data")
  .option("--output <value>", "save raw tx in datadir without actually sending tx")
  .option("--threshold <value>", "threshold to recover passphrase", 1)
  .option("--config <value>", "the location where the configuration file", "./config_frontNode.toml")
  .option("--chain <value>", "target contracts, 'all' for all chains in contract-deployer", "cypress")
  .option("--compile", "if true, only compile is performed")
  .option("--test", "test in a virtual chain using simulated backend")
  .option(
    "--filter <value>",
    "if listing numbers by separated by ',', only the deploy object in the file with the corresponding number in the migrations folder is applied"
  )
  .option("--lock", "if true, from key will be changed to the lock state after signing first tx")
  .option("--unlock", "if true, from key will be not changed to the lock state after signing first tx")
  .option("--keyhash", "if true, check the 2 bytes of the shared key hash first")
  .option("--keyhash", "if true, check the 2 bytes of the shared key hash first")
  .option("--message <value>", "message to sign")
  .option("--update", "if true, execute updateRoleKey")
  .option("--keytest", "if true, execute updateRoleKey test")
  .option("--name <value>", "contrects name")
  .option("--project <value>", "project name")
  .option("--file <value>", "file name")
  .option("--file <value>", "file name")
  .option("--abstract", "create abstract contract")
  .option("--interface", "create contract interface")
  .option("--interface", "create contract interface")
  .option("--record", "record tx receipt")
  .option("--multi", "transfer coin with multi txs")
  .option("--allow", "allow to sign tx without check process")
  .option("--pack <value>", "number of txs to be send simultaneously", 1)
  .option("--ledger", "allow to use ledger")
  .option("--payer", "allow to use fee payer");

// Add commands here using program.command(...)
program.command("deploy").description("Contract Deploy and Make Transaction To The Contracts Deployed.");
program.command("genkey").description("Generating Account On Keystore");
program.command("check").description("Checking Passphrase Of Account On Keystore");
program.command("update").description("Updaging Passphrase Of Account On Keystore");
program.command("console").description("Running console");
program.command("create").description("Create project directory");
program.command("gen").description("Generating contract file and supporting files");
program.command("manager").description("manage lots of token txs");
program.command("send").description("Send signed tx from data dir");
program.command("sign").description("Sign tx or msg from data dir");
program.command("transfercoin").description("Transfer wemix coin to wallet");

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
