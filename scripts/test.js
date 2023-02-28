// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const prompt = require('prompt-sync')();

async function main() {

const poolerL2Addr = "0x819D611D42a8560B5213359b3DF57ED757eF40f7";
const gateL2addr = "0xbF78833654557Ad80A6464C57B6E8ACA4622360C";
const gateL1addr = "0x9435a0e6d8a42ae3907a9C48113d322b97244e61";
const poolerL1addr2 = "0x66e893FE10861421cD69A5cD5cCdA3e0613899Ce";


// get deployed GateL2 contract
const GateL2 = await hre.ethers.getContractFactory("GateL2");
const gate2 = await GateL2.attach(
  gateL2addr
);
// get deployed PoolerL2 contract
const PoolerL2 = await hre.ethers.getContractFactory("PoolerL2");
const pooler2 = await PoolerL2.attach(
    poolerL2Addr
);
// get deployed GateL1 contract
const GateL1 = await hre.ethers.getContractFactory("GateL1");
const gate1 = await GateL1.attach(
    gateL1addr
);
// get deployed PoolerL1 contract
const PoolerL1 = await hre.ethers.getContractFactory("PoolerL1");
const pooler1 = await PoolerL1.attach(
    poolerL1addr2
);

// deposit on l2
const deposit = await pooler2.deposit(1000000000000000000);
await deposit.wait();
console.log("Deposited 1 token to L2");


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
