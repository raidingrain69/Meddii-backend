import { describe, it } from "node:test";
import assert from "node:assert/strict";
import hre from "hardhat";

describe("Medichain", () => {
  it("Should verify the doctor", async () => {
    // We cast to 'any' to stop the TypeScript error
    const env = await hre as any; 
    const viem = env.viem;

    // 1. Setup
    const [admin, doctor] = await viem.getWalletClients();
    const medichain = await viem.deployContract("Medichain");

    // 2. Action: Verify Doctor
    console.log("    > Verifying Dr. House...");
    await medichain.write.verifyDoctor([doctor.account.address, "Dr. House"]);

    // 3. Check Data
    const doctorData = await medichain.read.doctors([doctor.account.address]);
    assert.equal(doctorData[1], true);
    
    console.log("✅ Doctor verification test passed!");
  });
});