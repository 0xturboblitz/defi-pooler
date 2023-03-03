const hre = require("hardhat");
const prompt = require('prompt-sync')();

async function main() {
  const depositor = new ethers.Wallet(process.env.PKEY, ethers.provider);
  const driver = new ethers.Wallet(process.env.PKEY2, ethers.provider);

  const gateL2addr = "0xc62BdB14Fe2f315e4E4DdDa7ca89E600371eaB64"
  const poolerL2addr = "0x550E0B9dd93d8DB3e64e9EEd79e5Df0Fd43F62da"

  const gateL1addr = "0x2D931091D2c9fC0e6Bf6494847607f839B9a2d7A";
  const poolerL1addr = "0x9b0CDb0251bfD79694A13efF2EF4AaDB2705d5f8";
  const fusdcAddressL1 = "0xff369555331c7A1B5E0a59BF6A51BADde7416cB6";

  const ausdcL1 = await ethers.getContractAt("USDC", fusdcAddressL1)
  const gateL1 = await ethers.getContractAt("GateL1", gateL1addr);
  const poolerL1 = await ethers.getContractAt("PoolerL1", poolerL1addr);

  // 10 USDC have to have been deposited already on L1
  const launchBus = await poolerL1.connect(driver).launchBus({
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
