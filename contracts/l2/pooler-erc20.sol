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

    constructor(address _usdc, address _bridge) ERC20("pooled USDC", "pUSDC") {
        usdc = _usdc;
        bridge = _bridge;
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

        uint256 originalAmount = depositAmount / (1 - feeRate / 10000);
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

        uint256 fee = (amount * feeRate) / 10000;
        feeBucket += fee;

        withdrawsWaiting[msg.sender] = amount - fee;
        totalAmountToWithdraw += amount - fee;

        _burn(msg.sender, amount);
        withdrawQueue.push(msg.sender);
    }

    function cancelWithdraw() public notDuringRide {
        uint256 withdrawAmount = withdrawsWaiting[msg.sender];

        require(withdrawAmount > 0, "No deposit ticket found");

        uint256 originalAmount = withdrawAmount / (1 - feeRate / 10000);
        uint256 fee = originalAmount - withdrawAmount;

        feeBucket -= fee;
        totalAmountToWithdraw -= withdrawAmount;

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
            gasLimit
        );
    }

    function bridgeCallBack(
        uint256 currentPrice,
        uint256 amountWithdrawn
    ) public {
        require(msg.sender == bridge, "Only bridge can call this function");
        require(rideOngoing == true, "No ride in progress");

        // convert Deposits into pUSDC with currentPrice
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
            // transfer(user, amount)

            _mint(user, amount / currentPrice);
            delete withdrawsWaiting[user];
        }
        delete withdrawQueue;
        totalAmountToWithdraw = 0;

        rideOngoing = false;
    }

    function _sendRequestToBridge(
        uint256 amountToDeposit,
        uint256 amountToWithdraw,
        uint256 gasLimit
    ) internal {}
}
