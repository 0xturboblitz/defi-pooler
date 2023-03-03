const hre = require("hardhat");
const prompt = require('prompt-sync')();

async function main() {
  const depositor = new ethers.Wallet(process.env.PKEY, ethers.provider);
  const driver = new ethers.Wallet(process.env.PKEY2, ethers.provider);

  const poolerL2addr = "0x97262C64892E498A675bE13bd24F2fdc69082E08"
  const ausdcAddressL2 = "0x2c852e740B62308c46DD29B982FBb650D063Bd07";

  const ausdcL2 = await ethers.getContractAt("USDC", ausdcAddressL2)
  const poolerL2 = await ethers.getContractAt("PoolerL2", poolerL2addr);

  // deposit on l2
  const approve = await ausdcL2.connect(depositor).approve(poolerL2.address, "10000000");
  console.log("approve tx:", approve.hash)
  await approve.wait();
  const deposit = await poolerL2.connect(depositor).deposit("10000000"); // deposit 10 aUSDC
  console.log("deposit tx:", deposit.hash)
  await deposit.wait();
  console.log("Deposited 10 aUSDC to L2 pooler");

  const launchBus = await poolerL2.connect(driver).launchBus({
    value: ethers.utils.parseEther("0.3")
  });
  console.log("LaunchBus tx:", launchBus.hash)
  await launchBus.wait();
  console.log("Launched Bus");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
