const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("WithoutFork", function () {
  async function deployFixture() {
    const [user, otherUser, thirdUser] = await ethers.getSigners();

    const USDC = await ethers.getContractFactory("ExampleERC20");
    const usdc = await USDC.deploy("USD Coin", "USDC");

    // const PUSDC = await ethers.getContractFactory("FUSDC");
    // const pusdc = await PUSDC.deploy("Flux USDC", "FUSDC");

    // const Gateway = await ethers.getContractFactory("GatewayL2");
    // const gateway = await Gateway.deploy(user.address); //replace with gateway
    
    const PoolerL2 = await ethers.getContractFactory("PoolerL2");
    const poolerL2 = await PoolerL2.deploy(usdc.address, user.address); //replace with gateway

    // const PoolerL1 = await ethers.getContractFactory("PoolerL1");
    // const poolerL1 = await PoolerL1.deploy(usdc.address, user.address); //replace with gateway
    
    return { user, otherUser, thirdUser, usdc, poolerL2 };
  }

  describe("Deposit", function () {
    it("Should be able to deposit", async function () {
      const { user, usdc, poolerL2 } = await loadFixture(deployFixture);

      await usdc.approve(poolerL2.address, 1000000);
      await poolerL2.deposit(1000000);

      expect(await poolerL2.depositsWaiting(user.address)).to.equal(995000);
      expect(await poolerL2.feeBucket()).to.equal(5000);
    });

    it("Should be able to cancel deposits", async function () {
      const { user, usdc, poolerL2 } = await loadFixture(deployFixture);

      await usdc.approve(poolerL2.address, 1000000);
      await poolerL2.deposit(1000000);

      await poolerL2.cancelDeposit();
      
      expect(await poolerL2.feeBucket()).to.equal(0);
      expect(await poolerL2.depositsWaiting(user.address)).to.equal(0);
      expect(await usdc.balanceOf(user.address)).to.equal("100000000");
    });
  });

  describe("Withdraw", function () {
    it("Should be able to withdraw", async function () {
      const { user, poolerL2 } = await loadFixture(deployFixture);

      await poolerL2.approve(poolerL2.address, 1000000);
      await poolerL2.withdraw(1000000);

      expect(await poolerL2.withdrawsWaiting(user.address)).to.equal(1000000);
    });

    it("Should be able to cancel withdraws", async function () {
      const { user, usdc, poolerL2 } = await loadFixture(deployFixture);

      await poolerL2.approve(poolerL2.address, 1000000);
      await poolerL2.withdraw(1000000);

      await poolerL2.cancelWithdraw();
      
      expect(await poolerL2.feeBucket()).to.equal(0);
      expect(await poolerL2.withdrawsWaiting(user.address)).to.equal(0);
      expect(await poolerL2.balanceOf(user.address)).to.equal("10000000000");
    });
  });

  describe("Launch Bus", function () {
    it("Should be able to launch bus and receive it", async function () {
      const { user, usdc, poolerL2 } = await loadFixture(deployFixture);

      await usdc.approve(poolerL2.address, 1000000);
      await poolerL2.deposit(1000000);

      await poolerL2.launchBus();

      expect(await poolerL2.rideOngoing()).to.equal(true);
      expect(await poolerL2.driver()).to.equal(user.address);
      
      const price = 2
      await poolerL2.receiveBus(price, 0)

      // expect(await poolerL2.balanceOf(user.address)).to.equal("9950000");
      // expect(await poolerL2.depositsWaiting(user.address)).to.equal(0);
      // expect(await poolerL2.depositsWaiting(user.address)).to.equal(0);
      // expect(await poolerL2.depositQueue()).to.equal(0);
    });
  })
});


describe("LocalFork", function () {
  async function deployFixture() {
    const [user, otherUser, thirdUser] = await ethers.getSigners();

    const usdc = await ethers.getContractAt("USDC", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
    const fusdc = await ethers.getContractAt("fUSDC", "0x465a5a630482f3abd6d3b84b39b29b07214d19e5")
    console.log('usdc', usdc)

    const PUSDC = await ethers.getContractFactory("FUSDC");
    const pusdc = await PUSDC.deploy("Flux USDC", "FUSDC");

    const PoolerL2 = await ethers.getContractFactory("PoolerL2");
    const poolerL2 = await PoolerL2.deploy(usdc.address, user.address); //replace with gateway

    const PoolerL1 = await ethers.getContractFactory("PoolerL1");
    const poolerL1 = await PoolerL1.deploy(usdc.address, fusdc.address, user.address); //replace with gateway
    
    return { user, otherUser, thirdUser, usdc, fusdc, pusdc, poolerL2, poolerL1 };
  }

  describe("The Biiiiiggg Ride", function () {
    it("Should be able to do a full round", async function () {
      const { user, otherUser, thirdUser, usdc, poolerL2, poolerL1 } = await loadFixture(deployFixture);

      // user has 100 USDC, makes deposit request for 10
      await usdc.approve(poolerL2.address, 10000000);
      await poolerL2.deposit(10000000);

      expect(await poolerL2.depositsWaiting(user.address)).to.equal(9950000);
      expect(await poolerL2.feeBucket()).to.equal(50000);

      // otherUser has 100 pUSDC, makes withdraw request for 10
      await poolerL2.connect(otherUser).deposit(1000000000);

      expect(await poolerL2.withdrawsWaiting(otherUser.address)).to.equal(1000000000);

      // mocking bus going and coming back:
      await poolerL2.connect(thirdUser).launchBus();

      await usdc.connect("").transfer()
      await poolerL1.receiveBus(9950000, 1000000000)
      

      expect(await poolerL2.rideOngoing()).to.equal(true);
      expect(await poolerL2.driver()).to.equal(user.address);
      
      const price = 2
      await poolerL2.receiveBus(9950000, 1000000000)

      // expect(await poolerL2.balanceOf(user.address)).to.equal("9950000");
      // expect(await poolerL2.depositsWaiting(user.address)).to.equal(0);
      // expect(await poolerL2.depositsWaiting(user.address)).to.equal(0);
      // expect(await poolerL2.depositQueue()).to.equal(0);

    });
  })


})
