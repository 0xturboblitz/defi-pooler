// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IAxelarGateway} from "../interfaces/IAxelarGateway.sol";
import {IAxelarExecutable} from "../interfaces/IAxelarExecutable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PoolerL2} from "./PoolerL2.sol";

contract GateL2 is IAxelarExecutable, Ownable {
    string public destinationChain;
    string public l1GateAddress;
    string public symbol;
    address public iTokenAddress;
    address public pTokenAddress;
    address public pooler;

    constructor(
        address axelarGateway,
        string memory _destinationChain,
        string memory _symbol,
        address _iTokenAddress,
        address _pTokenAddress,
        address _pooler
    ) IAxelarExecutable(axelarGateway) {
        pooler = _pooler;
        destinationChain = _destinationChain;
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

        // check that the source address is the l1GateAddress
        require(
            keccak256(abi.encodePacked(sourceAddress)) ==
                keccak256(abi.encodePacked(l1GateAddress)),
            "Source address does not match"
        );

        //check that the source chain is the one expected
        require(
            keccak256(abi.encodePacked(destinationChain)) ==
                keccak256(abi.encodePacked(sourceChain)),
            "Source chain does not match"
        );

        //check that the amount is not greater than the balance of the gate
        require(
            amount <= IERC20(iTokenAddress).balanceOf(address(this)),
            "Amount is greater than the balance of the gate"
        );

        // get lasmintedamount and driver from payload
        (uint256 lastMintedAmount, address driver) = abi.decode(
            payload,
            (uint256, address)
        );

        //tranfer the amount of tokens to the pooler
        IERC20(iTokenAddress).transfer(pooler, amount);

        // call pooler to finalizw the unwarp
        PoolerL2(pooler).finalizeUnwarp(lastMintedAmount, driver);
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

    // owner only function to modify the l1GateAddress
    function setL1GateAddress(string memory _l1GateAddress) public onlyOwner {
        l1GateAddress = _l1GateAddress;
    }
}
