const hre = require("hardhat");

async function main() {
  console.log("Deploying CredentialVerifier contract...");

  const CredentialVerifier = await hre.ethers.getContractFactory("CredentialVerifier");
  const credentialVerifier = await CredentialVerifier.deploy();

  await credentialVerifier.waitForDeployment();
  
  const address = await credentialVerifier.getAddress();
  console.log(`CredentialVerifier deployed to: ${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });