const colors = {
  black: "\x1b[30m%s",
  red: "\x1b[31m%s",
  green: "\x1b[32m%s",
  yellow: "\x1b[33m%s",
  navy: "\x1b[34m%s",
  purple: "\x1b[35m%s",
  blue: "\x1b[36m%s",
  white: "\x1b[37m%s",
};

module.exports = {
  colors: colors,
  deploy: (params) =>
    console.log(`

  - ${params.key}
    - Contract Registry already exist
    - type              : ${params.type}
    - contract          : ${params.key}
    - chainID           : ${params.chainID}
    - from              : ${params.from}
    - to                : ${params.to}
    - gasTipCap         : ${params.maxPriorityFeePerGas}
    - gasFeeCap         : ${params.maxFeePerGas}
    - value             : ${params.value}
    - gasLimit          : ${params.gasLimit}
    
    `),
  receipt: (params) =>
    console.log(`
  
  - Receipt(${params.key})
    - status            : ${params.status}
    - type              : ${params.type}
    - blockNumber       : ${params.blockNumber}
    - blockHash         : ${params.blockHah}
    - transactionHash   : ${params.transactionHash}
    - contractAddress   : ${params.contractAddress}
    - gasUsed           : ${params.gasUsed}
    
    `),
};
