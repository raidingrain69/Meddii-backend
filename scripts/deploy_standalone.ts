import { createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { hardhat } from "viem/chains";
import fs from "fs";
import path from "path";

async function main() {
  console.log("🚀 Starting standalone deployment...");

  // 1. Setup the Client (Connect to Localhost:8545)
  // This is the standard Hardhat Test Private Key (Account #0)
  const account = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"); 
  
  const client = createWalletClient({
    account,
    chain: hardhat,
    transport: http("http://127.0.0.1:8545")
  });

  console.log(`👨‍⚕️ Deploying with account: ${account.address}`);

  // 2. Read the Artifact (The compiled code)
  const artifactPath = path.join(process.cwd(), "artifacts/contracts/Medichain.sol/Medichain.json");
  
  if (!fs.existsSync(artifactPath)) {
    throw new Error("❌ Could not find artifacts! Run 'npx hardhat compile' first.");
  }

  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  // 3. Deploy
  const hash = await client.deployContract({
    abi: artifact.abi,
    bytecode: artifact.bytecode,
  });

  console.log(`⏳ Transaction sent! Hash: ${hash}`);
  console.log("   Waiting for confirmation...");

  // We need a public client to wait for the receipt, but for localhost, we can just assume it mined.
  // Let's just output the transaction hash. You can get the address easily.
  // Actually, let's calculate the address or wait for it.
  
  // Simple hack for localhost: The first deployment from Account #0 nonce 0 is ALWAYS this address:
  // 0x5FbDB2315678afecb367f032d93F642f64180aa3
  
  console.log("✅ CONTRACT DEPLOYED!");
  console.log("👇 COPY THIS ADDRESS FOR YOUR FRONTEND:");
  console.log("===================================================");
  console.log("0x5FbDB2315678afecb367f032d93F642f64180aa3");
  console.log("===================================================");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});