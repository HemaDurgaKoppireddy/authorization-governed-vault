const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();

  console.log("====================================");
  console.log(" Authorization-Governed Vault Deploy ");
  console.log("====================================");
  console.log("Deployer Address :", deployer.address);
  console.log("Network Chain ID :", network.chainId);
  console.log("------------------------------------");

  // Deploy AuthorizationManager
  const AuthorizationManager = await hre.ethers.getContractFactory(
    "AuthorizationManager"
  );
  const authorizationManager = await AuthorizationManager.deploy(
    deployer.address
  );
  await authorizationManager.waitForDeployment();

  const authManagerAddress = await authorizationManager.getAddress();
  console.log("AuthorizationManager deployed at:", authManagerAddress);

  // Deploy SecureVault
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const secureVault = await SecureVault.deploy(authManagerAddress);
  await secureVault.waitForDeployment();

  const vaultAddress = await secureVault.getAddress();
  console.log("SecureVault deployed at:", vaultAddress);

  console.log("------------------------------------");
  console.log(" Deployment Successful ");
  console.log("====================================");
}

main().catch((error) => {
  console.error("Deployment failed:", error);
  process.exitCode = 1;
});
