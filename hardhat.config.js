require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();
require('hardhat-contract-sizer');
require("hardhat-gas-reporter");

module.exports = {
  solidity: "0.6.2",


  gasReporter: {
    currency: 'USD',
    enabled: false
  },

  paths: {
    artifacts: "./app/artifacts",
  },

  networks: {
    ropsten: {
      url: process.env.URL,
      accounts: [process.env.PRIVATE_KEY]

    },
    localhost: {
      url: "http://localhost:9111",
      accounts: [process.env.PRIVATE_KEY]
    }
  },

  etherscan: {

    apiKey: process.env.API
  },

  contractSizer: {
  alphaSort: true,
  runOnCompile: true,
  disambiguatePaths: false,
}

};
