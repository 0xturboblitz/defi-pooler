const hre = require("hardhat");
const prompt = require('prompt-sync')();

async function main() {
  const poolerL2addr = "0x97262C64892E498A675bE13bd24F2fdc69082E08"
  const poolerL2 = await ethers.getContractAt("PoolerL2", poolerL2addr);
  const res = await poolerL2.totalAmountToWithdraw();
  console.log('res', res)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
