// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IAxelarGateway} from "../interfaces/IAxelarGateway.sol";
import {IAxelarExecutable} from "../interfaces/IAxelarExecutable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GateL2  {

    address public axelarGateway; 
    string public destinationChain;
    string public l1GateAddress ;
    string public symbol;
    address public iTokenAddress;
    address public pTokenAddress;

    constructor(address _axelarGateway, string memory _destinationChain, string memory _l1GateAddress, string memory _symbol, address _iTokenAddress, address _pTokenAddress) {
        axelarGateway = _axelarGateway;
        destinationChain = _destinationChain;
        l1GateAddress = _l1GateAddress;
        symbol = _symbol;
        iTokenAddress = _iTokenAddress;
        pTokenAddress = _pTokenAddress;
    }

    // function to call the axelarGate to send tokens to L1
    // this function is called when the bus leaves the l2
    function warp(uint256 amountToDeposit, uint256 amountToWithraw) public {

        bytes memory payload = abi.encode(
            abi.encodeWithSignature(
                "receiveBus(uint256,uint256)",
                amountToDeposit,
                amountToWithraw
            )
        );

        // au choix: envoyer le montant de tokens manuellement ou 
        // envoyer le montant de tokens qui sont dans la gate
        // IAxelarGateway(axelarGateway).callContractWithToken(destinationChain, l1GateAddress, payload, symbol, getITokensToInvest());
        IAxelarGateway(axelarGateway).callContractWithToken(destinationChain, l1GateAddress, payload, symbol, amountToDeposit);
    }



    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal  {
        // check that the token is the one expected
        require(keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked(symbol)), "Token symbol does not match");

        // check that the amount is not 0
        require(amount > 0, "Amount must be greater than 0");

        // transfer the tokens to the gate
        IERC20(iTokenAddress).transferFrom(sourceAddress, address(this), amount);
    }

    // function to get the iToken balance of the gate
    // this is the amount of tokens that have been deposited
    // by users and are waiting to be sent to L1
    function getITokensToInvest() public view returns(uint256){
        return IERC20(iTokenAddress).balanceOf(address(this));
    }
}
