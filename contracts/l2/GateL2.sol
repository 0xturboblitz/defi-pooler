// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IAxelarGateway} from "../interfaces/IAxelarGateway.sol";
import {IAxelarExecutable} from "../interfaces/IAxelarExecutable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GateL2 is IAxelarExecutable {
    string public destinationChain;
    string public l1GateAddress;
    string public symbol;
    address public iTokenAddress;
    address public pTokenAddress;

    constructor(
        address axelarGateway,
        string memory _destinationChain,
        string memory _l1GateAddress,
        string memory _symbol,
        address _iTokenAddress,
        address _pTokenAddress
    ) IAxelarExecutable(axelarGateway) {
        destinationChain = _destinationChain;
        l1GateAddress = _l1GateAddress;
        symbol = _symbol;
        iTokenAddress = _iTokenAddress;
        pTokenAddress = _pTokenAddress;
    }

    // function to call the axelarGateway to send tokens to L1
    // this function is called when the bus leaves the l2
    function warp(uint256 amountToDeposit, uint256 amountToWithraw) public {
        bytes memory payload = abi.encode(abi.encode(amountToWithraw));

        // au choix: envoyer le montant de tokens manuellement ou
        // envoyer le montant de tokens qui sont dans la gate
        // IAxelarGateway(axelarGateway).callContractWithToken(destinationChain, l1GateAddress, payload, symbol, getITokensToInvest());
        gateway.callContractWithToken(
            destinationChain,
            l1GateAddress,
            payload,
            symbol,
            amountToDeposit
        );
    }

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal override {
        // check that the token is the one expected
        require(
            keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked(tokenSymbol)),
            "Token symbol does not match"
        );

        // check that the amount is not 0
        require(amount > 0, "Amount must be greater than 0");
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal override {
        revert("This function should not be called");
    }

    // function to get the iToken balance of the gate
    // this is the amount of tokens that have been deposited
    // by users and are waiting to be sent to L1
    // function getITokensToInvest() public view returns(uint256){
    //     return IERC20(iTokenAddress).balanceOf(address(this));
    // }
}
