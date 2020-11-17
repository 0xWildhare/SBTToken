require("@nomiclabs/hardhat-waffle");

require('dotenv').config();


module.exports = {
  solidity: "0.6.2",
  networks: {
    ropsten: {
      url: process.env.URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    localhost: {
      url: "http://localhost:9111",
      accounts: [process.env.PRIVATE_KEY]
    }
  }

};
