const {repl, replHowToUse} = require('../flags');

const {colors} = require('../../utils/console');
const global = require('../../utils/global');
const getProvider = require('../../utils/provider');

const {getNonce, getBalance} = require('../sender');

async function clearScreen() {
  const osType = process.platform;
  let command;

  switch (osType) {
    case 'win32':
      command = '\x1Bc';
      break;
    default:
      command = '\x1B[2J\x1B[0;0f';
  }

  process.stdout.write(command);
}

const inquirer = require('inquirer');

async function interactiveCLI(options) {
  const web3 = await getProvider();

  let nonce;
  if (options.from) {
    nonce = await getNonce(web3, options.from);
    console.log(`
> Created sender client
  - Address: ${options.from}
  - Nonce: ${nonce}`);
  } else {
    nonce = await getNonce(web3, global.owner);
    console.log(`
> Created sender client
  - Address: ${global.owner}
  - Nonce: ${nonce}`);
  }

  console.log(replHowToUse);

  while (true) {
    const response = await inquirer.prompt([{type: 'input', name: 'command', message: '>>'}]);

    const input = response.command.trim();
    const [command, ...args] = input.split(' ');

    if (command === '') continue;
    if (command === 'exit') break;

    switch (command) {
      case repl.help.name:
        console.log(replHowToUse);
        break;
      case repl.deploy.name:
        console.log('[Deploy]');
        break;
      case repl.call.name:
        console.log('[Call]');
        break;
      case repl.pcall.name:
        console.log('[Call proxy]');
        break;
      case repl.exec.name:
        console.log('[Execute]');
        break;
      case repl.pexec.name:
        console.log('[Execute proxy]');
        break;
      case repl.address.name:
        console.log('[Get contract address]');
        break;
      case repl.write.name:
        console.log('[Write tx files]');
        break;
      case repl.balance.name:
        const address = args[0];

        const {balanceWei, balanceEth} = await getBalance(web3, address);
        console.log(colors.yellow, `\n${address}`);
        console.log(colors.white, `[wei] ${balanceWei}`);
        console.log(colors.white, `[eth] ${balanceEth}\n`);

        break;
      case repl.transfercoin.name:
        console.log('[Transfer wemix coin]');
        break;
      case repl.eventlog.name:
        console.log('[Search event logs]');
        break;
      case repl.compile.name:
        console.log('[Recompile contracts]');
        break;
      case repl.readable.name:
        console.log('[readable]');
        break;
      case repl.abi.name:
        console.log('[ABI]');
        break;
      case repl.clear.name:
        clearScreen();
        break;
      default:
        console.log(`Unknown command: ${command}`);
    }
  }
}

module.exports = {clearScreen, interactiveCLI};
