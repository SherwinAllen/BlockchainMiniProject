require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// Go to https://www.alchemy.com and create a free API key
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

// Your MetaMask private key
const PRIVATE_KEY = process.env.PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.28",
      },
      {
        version: "0.8.20",
      }
    ],
  },
  networks: {
    // Default Hardhat Network (in-memory)
    hardhat: {},
    // Localhost Hardhat Node
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337
    },
    // Sepolia testnet
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [PRIVATE_KEY]
    }
  },
  paths: {
    artifacts: './frontend/src/artifacts',
  }
};
