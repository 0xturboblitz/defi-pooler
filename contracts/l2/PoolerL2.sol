// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract PoolerL2 is ERC20, Ownable {
    address public usdc;
    address public gateway;

    uint256 public feeRate = 50; // 0.50% fee
    uint256 public feeBucket;

    bool public rideOngoing;
    address public driver;

    uint256 public totalAmountToDeposit; //in USDC, 6 decimals
    mapping(address => uint256) public depositsWaiting;
    address[] public depositQueue;

    uint256 public totalAmountToWithdraw; //in pUSDC, 8 decimals
    mapping(address => uint256) public withdrawsWaiting;
    address[] public withdrawQueue;

    constructor(address _usdc, address _gateway) ERC20("pooled USDC", "pUSDC") {
        usdc = _usdc;
        gateway = _gateway;
        _mint(msg.sender, 10000000000); //Only for testing purposes
        _mint(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 10000000000); //Only for testing purposes
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    modifier notDuringRide() {
        require(rideOngoing == false, "Ride in progress. Try later");
        _;
    }

    function deposit(uint256 amount) public notDuringRide {
        uint256 fee = (amount * feeRate) / 10000;
        feeBucket += fee;

        depositsWaiting[msg.sender] = amount - fee;
        totalAmountToDeposit += amount - fee;
        depositQueue.push(msg.sender);

        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
    }

    function cancelDeposit() public notDuringRide {
        uint256 depositAmount = depositsWaiting[msg.sender];

        require(depositAmount > 0, "No deposit ticket found");

        uint256 originalAmount = (depositAmount * 10000) / (10000 - feeRate);
        uint256 fee = originalAmount - depositAmount;

        feeBucket -= fee;
        totalAmountToDeposit -= depositAmount;

        IERC20(usdc).transfer(msg.sender, originalAmount);
        delete depositsWaiting[msg.sender];
    }

    function withdraw(uint256 amount) public notDuringRide {
        uint256 position = balanceOf(msg.sender);

        require(position > 0, "No position found");
        require(position >= amount, "Cannot withdraw more than position");

        withdrawsWaiting[msg.sender] = amount;
        totalAmountToWithdraw += amount;

        _burn(msg.sender, amount);
        withdrawQueue.push(msg.sender);
    }

    function cancelWithdraw() public notDuringRide {
        uint256 withdrawAmount = withdrawsWaiting[msg.sender];

        require(withdrawAmount > 0, "No deposit ticket found");

        _mint(msg.sender, withdrawAmount);
        delete withdrawsWaiting[msg.sender];
    }

    function launchBus() public notDuringRide {
        require(
            totalAmountToDeposit > 0 || totalAmountToWithdraw > 0,
            "No deposits or withdraw to launch bus with"
        );
        rideOngoing = true;
        driver = msg.sender;

        // approve gateway
        IERC20(usdc).approve(gateway, totalAmountToDeposit);
        // IGateway(gateway).sendRequestToBridge(
        //     totalAmountToDeposit,
        //     totalAmountToWithdraw,
        // );
    }

    function receiveBus(uint256 currentPrice, uint256 amountWithdrawn) public {
        require(msg.sender == gateway, "Only gateway can call this function");
        require(rideOngoing == true, "No ride in progress");

        // convert deposits into pUSDC with currentPrice
        for (uint i = 0; i < depositQueue.length; i++) {
            address user = depositQueue[i];
            uint256 amount = depositsWaiting[user];
            _mint(user, amount / currentPrice);
            delete depositsWaiting[user];
        }

        delete depositQueue;
        totalAmountToDeposit = 0;

        //distribute withdraws according to withdrawQueue
        for (uint i = 0; i < withdrawQueue.length; i++) {
            address user = withdrawQueue[i];
            uint256 amount = withdrawsWaiting[user];
            IERC20(usdc).transfer(
                user,
                (amount * amountWithdrawn) / totalAmountToWithdraw
            );
            delete withdrawsWaiting[user];
        }
        delete withdrawQueue;
        totalAmountToWithdraw = 0;

        rideOngoing = false;
    }
}
