// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

import {GateL2} from "./GateL2.sol";

contract PoolerL2 is ERC20, Ownable {
    address public usdc;
    address public gateAddress;

    uint256 public feeRate = 50; // 0.50% fee
    uint256 public feeBucket;

    bool public rideOngoing;
    address public driver;

    mapping(address => uint256) public depositsWaiting;
    address[] public depositQueue;

    uint256 public totalAmountToWithdraw; //in pUSDC, 8 decimals
    mapping(address => uint256) public withdrawsWaiting;
    address[] public withdrawQueue;

    constructor(
        address _usdc,
        address _gateAddress
    ) ERC20("pooled USDC", "pUSDC") {
        usdc = _usdc;
        gateAddress = _gateAddress;
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
        depositQueue.push(msg.sender);

        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
    }

    function cancelDeposit() public notDuringRide {
        uint256 depositAmount = depositsWaiting[msg.sender];

        require(depositAmount > 0, "No deposit ticket found");

        uint256 originalAmount = (depositAmount * 10000) / (10000 - feeRate);
        uint256 fee = originalAmount - depositAmount;

        feeBucket -= fee;

        IERC20(usdc).transfer(msg.sender, originalAmount);
        delete depositsWaiting[msg.sender];

        for (uint i = 0; i < depositQueue.length; i++) {
            if (depositQueue[i] == msg.sender) {
                delete depositQueue[i];
            }
        }
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
        for (uint i = 0; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] == msg.sender) {
                delete withdrawQueue[i];
            }
        }
    }

    // called to start the ride
    function launchBus() public notDuringRide {
        uint256 totalAmountToDeposit = IERC20(usdc).balanceOf(address(this));

        require(
            totalAmountToDeposit > 0 || totalAmountToWithdraw > 0,
            "No deposits or withdraw to launch bus with"
        );
        rideOngoing = true;
        driver = msg.sender;

        IERC20(usdc).transfer(gateAddress, totalAmountToDeposit);

        GateL2(gateAddress).warp(totalAmountToDeposit, totalAmountToWithdraw);

        // IGateway(gateway).sendRequestToBridge(
        //     totalAmountToWithdraw,
        // );
    }

    // calleed by l2 gate after bus is back
    function receiveBus(uint256 lastMintedAmount) public {
        require(
            msg.sender == gateAddress,
            "Only gateway can call this function"
        );
        require(rideOngoing == true, "No ride in progress");

        // for each fUSDC minted on L1, mint pUSDC proportionately to deposits
        uint256 sumOfDepositAmounts = 0;
        for (uint i = 0; i < depositQueue.length; i++) {
            sumOfDepositAmounts += depositsWaiting[depositQueue[i]];
        }

        for (uint i = 0; i < depositQueue.length; i++) {
            address user = depositQueue[i];
            uint256 amount = depositsWaiting[user];
            _mint(user, (amount * lastMintedAmount) / sumOfDepositAmounts);
            // _mint(user, amount / currentPrice);
            delete depositsWaiting[user];
        }
        delete depositQueue;

        //distribute USDC received proportionately to withdraws in withdrawQueue
        uint256 amountWithdrawn = IERC20(usdc).balanceOf(address(this));
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
