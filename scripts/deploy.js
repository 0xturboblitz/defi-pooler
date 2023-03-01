// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const PoolerL1 = await hre.ethers.getContractFactory("PoolerL1");
  const poolerL1 = await PoolerL1.deploy(
    "0x86c01DD169aE6f3523D1919cc46bc224E733127F",
    "0x86c01DD169aE6f3523D1919cc46bc224E733127F",
    10
  );

  await poolerL1.deployed();

  console.log(
    `PoolerL1 deployed to ${poolerL1.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
