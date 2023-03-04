const hre = require("hardhat");
const prompt = require('prompt-sync')();

async function main() {
  const driver = new ethers.Wallet(process.env.PKEY, ethers.provider);


  const gateL1addr = "0x6f0772c30E606886498ED5dC039071096431A2E7";
  const poolerL1addr = "0x1C0E5B1D73d07b45008D0BF1EE7a9C7203cb4233";
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
