/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
module.exports = {
  solidity: "0.8.9",
  networks: {
    localhost: {
      url: "http://localhost:8545"
    },
    hardhat: {
      forking: {
        url: "https://eth-mainnet.g.alchemy.com/v2/pv-xSVPKpdeM_NXPsyr1n8rhpxvTnIDx",
        blockNumber: 15122100
      }
    }
  }
};

