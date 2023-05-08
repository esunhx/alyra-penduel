require('dotenv').config();

const Web3 = require("web3");
const HDWalletProvider = require('@truffle/hdwallet-provider');
const { abi, bytecode} = require("./../../client/src/contracts/Penduel.json");

// console.log("ABI",abi)
// console.log("MNEMONIC", process.env.MNEMONIC)

const web3 = new Web3(new HDWalletProvider({
  mnemonic: process.env.MNEMONIC,
  providerOrUrl: "http://localhost:8545",
  numAddresses: 3
}));

const Penduel = new web3.eth.Contract(abi);

word = "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
bet = web3.utils.toWei('0.000000000001', 'ether');
stake = web3.utils.toWei('0.000000000002', 'ether');

// console.log("BET", bet, "STAKE", stake)
// console.log(stake == 2*bet)


const deploy = async () => {
  const accounts = await web3.eth.getAccounts();
  console.log(accounts)
  const out = await Penduel.deploy({
    data: bytecode,
    arguments: [accounts[2], stake]
  }).send({
    from: accounts[2],
    value: bet,
    gas: 2000000
  });
  console.log("Contract deployed to address:", out.options.address);
}

deploy();

