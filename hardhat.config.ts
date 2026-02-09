import { defineConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";

export default defineConfig({
  solidity: "0.8.28",
  networks: {
    hardhat: {
      type: "edr-simulated",
      initialBaseFeePerGas: 0,
      chainId: 31337,
    },
    localhost: {
      type: "http",
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
  },
});