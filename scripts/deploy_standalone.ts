import { createWalletClient, createPublicClient, http, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { hardhat } from "viem/chains";
import fs from "fs";
import path from "path";

async function main() {
  console.log("🚀 Starting standalone deployment & seeding...");

  // --- CONFIGURATION ---
  // Account 0 (Admin)
  const adminAccount = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"); 
  // Account 1 (Doctor)
  const doctorAccount = privateKeyToAccount("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");
  // Account 2 (Patient)
  const patientAccount = privateKeyToAccount("0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a");

  // Client Setup
  const client = createWalletClient({
    chain: hardhat,
    transport: http("http://127.0.0.1:8545")
  });

  const publicClient = createPublicClient({
    chain: hardhat,
    transport: http("http://127.0.0.1:8545")
  });

  // --- 1. DEPLOYMENT ---
  const artifactPath = path.join(process.cwd(), "artifacts/contracts/Medichain.sol/Medichain.json");
  if (!fs.existsSync(artifactPath)) throw new Error("❌ Run 'npx hardhat compile' first.");
  
  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  console.log(`👨‍⚕️ Deploying Contract with Admin: ${adminAccount.address}`);
  
  const hash = await client.deployContract({
    abi: artifact.abi,
    bytecode: artifact.bytecode,
    account: adminAccount,
  });

  console.log(`⏳ Deploying... Hash: ${hash}`);
  
  // Wait for deployment
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  const contractAddress = receipt.contractAddress;

  if(!contractAddress) throw new Error("Deployment failed, no address returned.");

  console.log("✅ CONTRACT DEPLOYED AT:", contractAddress);
  console.log("===================================================");

  // --- 2. SEEDING DATA ---

  // A. Verify Doctor (Sent by Admin)
  console.log("1️⃣  Verifying Doctor (Account 1)...");
  const verifyTx = await client.writeContract({
    address: contractAddress,
    abi: artifact.abi,
    functionName: 'verifyDoctor',
    args: [doctorAccount.address, "Dr. Viem Auto"],
    account: adminAccount
  });
  await publicClient.waitForTransactionReceipt({ hash: verifyTx });

  // B. Create Patient Profile (Sent by Patient)
  console.log("2️⃣  Creating Patient Profile (Account 2)...");
  const profileTx = await client.writeContract({
    address: contractAddress,
    abi: artifact.abi,
    functionName: 'setProfile',
    args: ["John Doe", 30n, "Male", "Asthma, Nut Allergy"], // Note: 30n for BigInt
    account: patientAccount
  });
  await publicClient.waitForTransactionReceipt({ hash: profileTx });

  // C. Grant Access (Patient -> Doctor)
  console.log("3️⃣  Granting Doctor Access...");
  const grantTx = await client.writeContract({
    address: contractAddress,
    abi: artifact.abi,
    functionName: 'grantAccess',
    args: [doctorAccount.address],
    account: patientAccount
  });
  await publicClient.waitForTransactionReceipt({ hash: grantTx });

  // D. Upload Record (Doctor -> Patient)
  console.log("4️⃣  Doctor Uploading Record...");
  const uploadTx = await client.writeContract({
    address: contractAddress,
    abi: artifact.abi,
    functionName: 'addRecord',
    args: [patientAccount.address, "QmTESTHASH123", "Initial-Viem-Checkup.pdf"],
    account: doctorAccount
  });
  await publicClient.waitForTransactionReceipt({ hash: uploadTx });

  console.log("🎉 SUCCESS! Database pre-seeded.");
  console.log(`👉 Admin: ${adminAccount.address}`);
  console.log(`👉 Doctor: ${doctorAccount.address}`);
  console.log(`👉 Patient: ${patientAccount.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});