const hre = require("hardhat");
const prompt = require('prompt-sync')();

async function main() {
  const depositor = new ethers.Wallet(process.env.PKEY, ethers.provider);
  const driver = new ethers.Wallet(process.env.PKEY2, ethers.provider);

  const gateL2addr = "0xc62BdB14Fe2f315e4E4DdDa7ca89E600371eaB64"
  const poolerL2addr = "0x550E0B9dd93d8DB3e64e9EEd79e5Df0Fd43F62da"
  const ausdcAddressL2 = "0x2c852e740B62308c46DD29B982FBb650D063Bd07";

  const gateL1addr = "0x2D931091D2c9fC0e6Bf6494847607f839B9a2d7A";
  const poolerL1addr = "0x9b0CDb0251bfD79694A13efF2EF4AaDB2705d5f8";

  const ausdcL2 = await ethers.getContractAt("USDC", ausdcAddressL2)
  const gateL2 = await ethers.getContractAt("GateL2", gateL2addr);
  const poolerL2 = await ethers.getContractAt("PoolerL2", poolerL2addr);

  // deposit on l2
  const approve = await ausdcL2.connect(depositor).approve(poolerL2.address, "10000000");
  await approve.wait();
  const deposit = await poolerL2.connect(depositor).deposit("10000000"); // deposit 10 aUSDC
  await deposit.wait();
  console.log("Deposited 10 aUSDC to L2 pooler");

  await poolerL2.connect(driver).launchBus({
    value: ethers.utils.parseEther("0.1")
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
