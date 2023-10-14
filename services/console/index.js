const vorpal = require("vorpal")();

vorpal.delimiter(">>").show();

vorpal
  .command("exec transfercoin <tokenType> <tokenName> <fromAddress> <toAddress> <amount>", "Transfer coins.")
  .action(function (args, callback) {
    transferCoin(args.tokenType, args.tokenName, args.fromAddress, args.toAddress, args.amount);
    callback();
  });

function transferCoin(tokenType, tokenName, fromAddress, toAddress, amount) {
  const message = `Transferring ${amount} of ${tokenType} token named ${tokenName} from ${fromAddress} to ${toAddress}`;

  vorpal.ui.log(message);
}
