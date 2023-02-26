// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolerERC20 is ERC20, Ownable {
    address usdc;
    address bridge;

    uint256 feeRate = 25; // 0.25% fee
    uint256 feeBucket;

    uint256 currentEpoch;
    bool rideOngoing;

    uint256 public totalAmountToDeposit;
    mapping(address => uint256) depositsWaiting;
    address[] depositQueue;

    uint256 public totalAmountToWithdraw;
    mapping(address => uint256) withdrawsWaiting;
    address[] withdrawQueue;

    constructor(
        address _usdc,
        address _bridge
    ) ERC20("bangr pooled fUSDC", "bpfUSDC") {
        usdc = _usdc;
        bridge = _bridge;
    }

    modifier notDuringRide() {
        require(rideOngoing == false, "Ride in progress. Try later");
        _;
    }

    function deposit(uint256 amount) public notDuringRide {
        transferFrom(msg.sender, address(this), amount);

        fee = (amount * feeRate) / 10000;
        feeBucket += fee;

        depositsWaiting[msg.sender] = amount - fee;
        totalAmountToDeposit += amount - fee;
        depositQueue.push(msg.sender);
    }

    function cancelDeposit() public notDuringRide {
        uint256 deposit = depositsWaiting[msg.sender];

        require(deposit > 0, "No deposit ticket found");

        originalAmount = deposit / (1 - feeRate / 10000);
        fee = originalAmount - deposit;

        feeBucket -= fee;
        totalAmountToDeposit -= deposit;

        transfer(msg.sender, originalAmount);
        delete depositsWaiting[msg.sender];
    }

    function withdraw(uint256 amount) public notDuringRide {
        uint256 position = balanceOf(msg.sender);

        require(position > 0, "No position found");
        require(position >= amount, "Cannot withdraw more than position");

        fee = (amount * feeRate) / 10000;
        feeBucket += fee;

        withdrawsWaiting[msg.sender] = amount - fee;
        totalAmountToWithdraw += amount - fee;

        _burn(msg.sender, amount);
        withdrawQueue.push(msg.sender);
    }

    function cancelWithdraw() public notDuringRide {
        uint256 withdraw = withdrawsWaiting[msg.sender];

        require(withdraw > 0, "No deposit ticket found");

        originalAmount = withdraw / (1 - feeRate / 10000);
        fee = originalAmount - withdraw;

        feeBucket -= fee;
        totalAmountToWithdraw -= withdraw;

        _mint(msg.sender, originalAmount);
        delete withdrawsWaiting[msg.sender];
    }

    function launchBus(uint256 gasLimit) public notDuringRide {
        require(
            totalAmountToDeposit > 0 || totalAmountToWithdraw > 0,
            "No deposits or withdraw to launch bus with"
        );
        rideOngoing = true;

        // approve bridge
        _sendRequestToBridge(
            totalAmountToDeposit,
            totalAmountToWithdraw,
            feeBucket,
            gasLimit
        );
    }

    function bridgeCallBack(
        uint256 currentPrice,
        uint256 amountWithdrawn
    ) public {
        require(msg.sender == bridge, "Only bridge can call this function");
        require(rideOngoing == true, "No ride in progress");

        // convert Deposits into bpfUSDC with currentPrice
        for (i = 0; i < depositQueue.length; i++) {
            address user = depositQueue[i];
            uint256 amount = depositsWaiting[user];
            _mint(user, amount / currentPrice);
            delete depositsWaiting[user];
        }

        delete depositQueue;
        totalAmountToDeposit = 0;

        //distribute withdraws according to withdrawQueue
        totalAmountToWithdraw = 0;

        rideOngoing = false;
    }
}
