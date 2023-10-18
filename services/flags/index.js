module.exports = {
  // Options Flag
  options: {
    url: { name: "--url <value>", usage: "node url", value: "https://api.test.wemix.com/" },
    contract: { name: "--contract <value>", usage: "root directory for contracts source code to compile" },
    owner: { name: "--owner <value>", usage: "owner address" },
    from: { name: "--from <value>", usage: "tx sender" },
    dataDir: { name: "--datadir <value>", usage: "the location where raw txs", value: "./data" },
    output: { name: "--output <value>", usage: "save raw tx in datadir without actually sending tx" },
    threshold: { name: "--threshold <value>", usage: "threshold to recover passphrase", value: 1 },
    config: { name: "--config <value>", usage: "the location where the configuration file", value: "./config.toml" },
    chain: { name: "--chain <value>", usage: "target contracts, 'all' for all chains in contract-deployer", value: "wemix" },
    compile: { name: "--compile", usage: "if true, only compile is performed" },
    lock: { name: "--lock", usage: "if true, from key will be changed to the lock state after signing first tx" },
    unlock: { name: "--unlock", usage: "if true, from key will be not changed to the lock state after signing first tx" },
    keyhash: { name: "--keyhash", usage: "if true, check the 2 bytes of the shared key hash first" },
    keystore: { name: "--keystore <value>", usage: "the location where keystore" },
    message: { name: "--message <value>", usage: "message to sign" },
    update: { name: "--update", usage: "if true, execute updateRoleKey" },
    keytest: { name: "--keytest", usage: "if true, execute updateRoleKey test" },
    name: { name: "--name <value>", usage: "contrects name" },
    project: { name: "--project <value>", usage: "project name" },
    file: { name: "--file <value>", usage: "file name" },
    abstract: { name: "--abstract", usage: "create abstract contract" },
    interface: { name: "--interface", usage: "create contract interface" },
    record: { name: "--record", usage: "record tx receipt" },
    multi: { name: "--multi", usage: "transfer coin with multi txs" },
    allow: { name: "--allow", usage: "allow to sign tx without check process" },
    pack: { name: "--pack <value>", usage: "number of txs to be send simultaneously", value: 1 },
    ledger: { name: "--ledger", usage: "allow to use ledger" },
    payer: { name: "--payer", usage: "allow to use fee payer" },
    test: { name: "--test", usage: "test in a virtual chain using simulated backend" },
    filter: {
      name: "--filter <value>",
      usage:
        "if listing numbers by separated by ',' only the deploy object in the file with the corresponding number in the migrations folder is applied",
    },
  },
  // Commands Flag
  commands: {
    deploy: { name: "deploy", description: "Contract Deploy and Make Transaction To The Contracts Deployed" },
    genkey: { name: "genkey", description: "Generating Account On Keystore" },
    check: { name: "check", description: "Checking Passphrase Of Account On Keystore" },
    update: { name: "update", description: "Updaging Passphrase Of Account On Keystore" },
    console: { name: "console", description: "Running console" },
    create: { name: "create", description: "Create project directory" },
    gen: { name: "gen", description: "Generating contract file and supporting files" },
    manager: { name: "manager", description: "manage lots of token txs" },
    send: { name: "send", description: "Send signed tx from data dir" },
    sign: { name: "sign", description: "Sign tx or msg from data dir" },
    transfercoin: { name: "transfercoin", description: "Transfer wemix coin to wallet" },
  },
  // REPL Commands
  repl: {
    deploy: { name: "deploy", description: "Deploy contract", help: "balance [address]: Check the balance of the specified address" },
    call: { name: "call", description: "Call" },
    pcall: { name: "pcall", description: "Call proxy" },
    exec: { name: "exec", description: "Execute" },
    pexec: { name: "pexec", description: "Execute proxy" },
    address: { name: "address", description: "Get contract address" },
    write: { name: "write", description: "Write tx files" },
    balance: { name: "balance", description: "Get address coin balance" },
    transfercoin: { name: "transfercoin", description: "Transfer wemix coin" },
    eventlog: { name: "eventlog", description: "Search event logs" },
    compile: { name: "compile", description: "Recompile contracts" },
    readable: { name: "readable" },
    abi: { name: "abi" },
    clear: { name: "clear" },
    help: { name: "help" },
  },
  // REPL How To Use
  replHowToUse: `
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
    abi\n`,
};
