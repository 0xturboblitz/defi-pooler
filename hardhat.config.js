require("@nomicfoundation/hardhat-toolbox");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: ["2ccfe123b7e5a3f6672cc6956f3c25b7fa25df1365cf0879a207756a68ac3f8b"]
    },
    mumbai: {
      url: "https://rpc.ankr.com/polygon_mumbai",
      accounts: ["2ccfe123b7e5a3f6672cc6956f3c25b7fa25df1365cf0879a207756a68ac3f8b"]
    }
  } 
};
