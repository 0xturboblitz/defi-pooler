const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("PoolerL2", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [user, otherUser] = await ethers.getSigners();

    console.log('user', user.address)
    
    const USDC = await ethers.getContractFactory("ExampleERC20");
    const usdc = await USDC.deploy("USD Coin", "USDC");

    const Gateway = await ethers.getContractFactory("GatewayL2");
    const gateway = await Gateway.deploy(user.address); //replace with gateway
    
    const Pooler = await ethers.getContractFactory("PoolerL2");
    const pooler = await Pooler.deploy(usdc.address, user.address); //replace with gateway
    
    return { user, otherUser, usdc, gateway, pooler };
  }

  describe("Deposit", function () {
    it("Should be able to deposit", async function () {
      const { user, usdc, pooler } = await loadFixture(deployFixture);

      await usdc.approve(pooler.address, 1000000);
      await pooler.deposit(1000000);

      expect(await pooler.depositsWaiting(user.address)).to.equal(995000);
      expect(await pooler.feeBucket()).to.equal(5000);
    });

    it("Should be able to cancel deposits", async function () {
      const { user, usdc, pooler } = await loadFixture(deployFixture);

      await usdc.approve(pooler.address, 1000000);
      await pooler.deposit(1000000);

      await pooler.cancelDeposit();
      
      expect(await pooler.feeBucket()).to.equal(0);
      expect(await pooler.depositsWaiting(user.address)).to.equal(0);
      expect(await usdc.balanceOf(user.address)).to.equal("1000000000");
    });
  });

  describe("Withdraw", function () {
    it("Should be able to withdraw", async function () {
      const { user, pooler } = await loadFixture(deployFixture);

      await pooler.approve(pooler.address, 1000000);
      await pooler.withdraw(1000000);

      expect(await pooler.withdrawsWaiting(user.address)).to.equal(1000000);
    });

    it("Should be able to cancel withdraws", async function () {
      const { user, usdc, pooler } = await loadFixture(deployFixture);

      await pooler.approve(pooler.address, 1000000);
      await pooler.withdraw(1000000);

      await pooler.cancelWithdraw();
      
      expect(await pooler.feeBucket()).to.equal(0);
      expect(await pooler.withdrawsWaiting(user.address)).to.equal(0);
      expect(await pooler.balanceOf(user.address)).to.equal("1000000000");
    });
  });

  describe("Launch Bus", function () {
    it("Should be able to launch bus and receive it", async function () {
      const { user, usdc, pooler } = await loadFixture(deployFixture);

      await usdc.approve(pooler.address, 1000000);
      await pooler.deposit(1000000);

      await pooler.launchBus("123123");

      expect(await pooler.rideOngoing()).to.equal(true);
      expect(await pooler.driver()).to.equal(user.address);
      
      const price = 2
      await pooler.gatewayCallBack(price, 0)

      expect(await pooler.balanceOf(user.address)).to.equal("9950000");
      expect(await pooler.depositsWaiting(user.address)).to.equal(0);
      expect(await pooler.depositsWaiting(user.address)).to.equal(0);
      // expect(await pooler.depositQueue()).to.equal(0);


    });
  
  })
});
