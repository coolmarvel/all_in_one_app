const global = require("../../../../utils/global");

module.exports = {
  arguments: {
    owners: [global.multiSig_owner1, global.multiSig_owner2, global.multiSig_owner3],
    quorum: 2,
  },
};
