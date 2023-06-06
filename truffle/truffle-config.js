const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();

module.exports = {
  contracts_directory: './../truffle/contracts/',
  contracts_build_directory: './../client/src/contracts',
  networks: {
    development: {
        host: '127.0.0.1', 
        port: 8545,
        network_id: '*',
        WebSocket: true
    },
    goerli: {
      provider: function () {
          return new HDWalletProvider(
              `${process.env.MNEMONIC}`,
              `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`
          );
      },
      network_id: 5,
    },
    sepolia: {
      provider: function () {
        return new HDWalletProvider(
          `${process.env.MNEMONIC}`,
          `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`
        )
      }
    }
  },
  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions: {
        gasPrice: 1,
        token: 'ETH',
        showTimeSpent: true,
    },
  },
  compilers: {
    solc: {
        version: '0.8.18',
        settings: {
            optimizer: {
                enabled: false,
                runs: 200,
            },
        },
    },
  }
}