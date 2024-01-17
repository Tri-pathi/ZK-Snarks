// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const  hre  = require("hardhat");

async function main() {
  // deploy hasher
  const Mimc7Hasher = await hre.ethers.getContractFactory("MIMC7Hasher");
  const mimc7Hasher = await Mimc7Hasher.deploy();
  await mimc7Hasher.deployed();

  //deploy verifier
  const Verifier = await hre.ethers.getContractFactory("Verifier");
  const verifier = await Verifier.deploy();
  await verifier.deployed();


  // deploy tornado
  const ZKPStoreFactory = await hre.ethers.getContractFactory("ZKPStore");
  const ZKPStore = await ZKPStoreFactory.deploy(mimc7Hasher.address, verifier.address);
  await ZKPStore.deployed();
  console.log(mimc7Hasher.address);
  console.log(verifier.address);
  console.log(ZKPStore.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
