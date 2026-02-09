import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MedichainModule = buildModule("MedichainModule", (m) => {
  // Deploy the contract
  const medichain = m.contract("Medichain");

  // Return it so we can use it
  return { medichain };
});

export default MedichainModule;