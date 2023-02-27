require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
      accounts: ["2ccfe123b7e5a3f6672cc6956f3c25b7fa25df1365cf0879a207756a68ac3f8b"]
    },
    arbitest: {
      url: "https://endpoints.omniatech.io/v1/arbitrum/goerli/public",
      accounts: ["2ccfe123b7e5a3f6672cc6956f3c25b7fa25df1365cf0879a207756a68ac3f8b"]
    }
  } 
};
