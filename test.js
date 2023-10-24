const getProvider = require("./utils/provider");
const { logger } = require("./utils/winston");

const test = async () => {
  try {
    const wemix = await getProvider();

    
  } catch (error) {
    logger.error(error.message);
  }
};
