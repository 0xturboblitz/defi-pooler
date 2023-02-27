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

    uint256 public lastMintedAmount;

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
    function finalizeWarp(uint256 totalAmountToWithdraw) public notDuringRide {
        require(msg.sender == gateway, "Only gateway can call this function");
        rideOngoing = true;

        uint256 totalAmountToDeposit = IERC20(usdc).balanceOf(address(this));
        // Deposit
        uint256 oldfUSDCbalance = IERC20(fusdc).balanceOf(address(this));
        IERC20(usdc).approve(fusdc, totalAmountToDeposit);
        assert(CErc20(fusdc).mint(totalAmountToDeposit) == 0); // mints the cTokens and asserts there is no error
        uint256 newfUSDCbalance = IERC20(fusdc).balanceOf(address(this));
        lastMintedAmount = newfUSDCbalance - oldfUSDCbalance;

        // Withdraw
        assert(CErc20(fusdc).redeem(totalAmountToWithdraw) == 0); // redeems usdc and asserts there is no error
    }

    // pour lancer le retour
    // call la gate l1
    // lastExchange rate et amount withdrawn
    function launchBus() public {
        require(rideOngoing == true, "No ride in progress");

        uint256 lastUSDCAmountWithdrawn = IERC20(usdc).balanceOf(address(this));

        IERC20(usdc).transfer(gateway, lastUSDCAmountWithdrawn);
        // IGateway(gateway).sendRequestToBridge(
        //     lastMintedAmount,
        // );
        rideOngoing = false;
    }
}
