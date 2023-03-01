require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: "https://eth-goerli.public.blastapi.io",
      accounts: [process.env.PKEY]
    },
    optiGoerli: {
      url: "https://goerli.optimism.io",
      accounts: [process.env.PKEY]
    },
  },

};
