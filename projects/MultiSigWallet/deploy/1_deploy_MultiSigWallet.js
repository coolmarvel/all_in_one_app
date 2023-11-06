const global = require("../../../utils/global");

module.exports = {
  owners: [global.multiSig_owner1, global.multiSig_owner2, global.multiSig_owner3],
  quorum: 2,
  /**
   * 여기다가 차라리 deploy logic을 추가해서 이 파일을 읽을 수 있도록 변경하자 어때?
   */
};
