import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    local :{
      url : "http://127.0.0.1:8545",
      chainId: 31337,
      allowUnlimitedContractSize: true,
      gasPrice: 3000000000,
      // blockGasLimit: 0x1fffffffffffff,
    },
    ccmedia :{
      url : "http://192.168.1.83:30300",
      chainId: 1337,
      accounts: [
        '0xA3CC7563B149BC4F884EA43C2DA63D920F96613E1704EE51388417684264E1D1',
      ],
      gasPrice: 0,
      gas: 0x1fffffffffffff,
    },
    sepolia :{
      url : "https://eth-sepolia.api.onfinality.io/public",
      chainId: 11155111,
    },
  },
  mocha: {
    timeout: 0
  },
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          viaIR: true,  
        },
      },
    ],
  },
};

export default config;
