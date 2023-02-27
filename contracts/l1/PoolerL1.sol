// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CErc20 {
    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function exchangeRateCurrent() external returns (uint);
}

contract PoolerL1 {
    address public usdc;
    address public fusdc;
    address public gateway;

    bool public rideOngoing;

    uint256 public lastExchangeRate;

    constructor(address _usdc, address _fusdc, address _gateway) {
        usdc = _usdc;
        fusdc = _fusdc;
        gateway = _gateway;
    }

    modifier notDuringRide() {
        require(rideOngoing == false, "Ride in progress. Try later");
        _;
    }

    // call par la gate l1 apres que le bus aller soit arrivé
    function receiveBus(
        uint256 totalAmountToDeposit,
        uint256 totalAmountToWithdraw
    ) public notDuringRide {
        require(msg.sender == gateway, "Only gateway can call this function");
        rideOngoing = true;

        // Deposit
        IERC20(usdc).approve(fusdc, totalAmountToDeposit);
        assert(CErc20(fusdc).mint(totalAmountToDeposit) == 0); // mints the cTokens and asserts there is no error

        // Withdraw
        assert(CErc20(fusdc).redeem(totalAmountToWithdraw) == 0); // redeems usdc and asserts there is no error

        lastExchangeRate = CErc20(fusdc).exchangeRateCurrent();
    }

    // pour lancer le retour
    // call la gate l1 
    // lastExchange rate et amount withdrawn
    function launchBus() public {
        require(rideOngoing == true, "No ride in progress");

        rideOngoing = false;
    }
}
