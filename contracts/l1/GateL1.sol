// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IAxelarExecutable} from "../interfaces/IAxelarExecutable.sol";
import {IAxelarGateway} from "../interfaces/IAxelarGateway.sol";
import {PoolerL1} from "./PoolerL1.sol";

contract GateL1 is IAxelarExecutable {
    string public destinationChain;
    string public l2GateAddress;
    string public symbol;
    address public iTokenAddress;
    address public pTokenAddress;
    address public pooler;

    constructor(
        address axelarGateway,
        string memory _destinationChain,
        string memory _l2GateAddress,
        string memory _symbol,
        address _iTokenAddress,
        address _pTokenAddress
    ) IAxelarExecutable(axelarGateway) {
        destinationChain = _destinationChain;
        l2GateAddress = _l2GateAddress;
        symbol = _symbol;
        iTokenAddress = _iTokenAddress;
        pTokenAddress = _pTokenAddress;
    }

    // function to call the axelarGateway to send tokens to L2
    // this function is called when the bus leaves the l1
    function unWarp(
        uint256 lastMintedAmount,
        uint256 lastUSDCAmountWithdrawn,
        address driver
    ) public {
        bytes memory payload = abi.encode(abi.encode(lastMintedAmount, driver));

        // au choix: envoyer le montant de tokens manuellement ou
        // envoyer le montant de tokens qui sont dans la gate
        // IAxelarGateway(axelarGateway).callContractWithToken(destinationChain, l1GateAddress, payload, symbol, getITokensToInvest());
        gateway.callContractWithToken(
            destinationChain,
            l2GateAddress,
            payload,
            symbol,
            lastUSDCAmountWithdrawn
        );
    }

    // implement functions from IAxelarExecutable

    // function called when the tokens arrive on L1
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
        // check that the source chain is the one expected
        require(
            keccak256(abi.encodePacked(destinationChain)) ==
                keccak256(abi.encodePacked(sourceChain)),
            "Source chain does not match"
        );

        // get the amount to withdraw from the payload
        uint256 amountToWithdraw = abi.decode(payload, (uint256));

        // call the pooler to invest the tokens
        PoolerL1(pooler).finalizeWarp(amountToWithdraw);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal override {
        // check that the source chain is the one expected
        require(
            keccak256(abi.encodePacked(destinationChain)) ==
                keccak256(abi.encodePacked(sourceChain)),
            "Source chain does not match"
        );
    }
}
