// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IAxelarGater} from "../interfaces/IAxelarGateway.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GateL2  {

    address public axelarGate; 
    string public destinationChain;
    string public l1GateAddress ;
    string public symbol;
    address public iTokenAddress;
    address public pTokenAddre

    constructor(address axelarGate, string memory destinationChain, string memory destinationGateAddreaa, string memory symbol){
        this.axelarGate = axelarGate;
        this.destinationChain = destinationChain;
        this.destinationGateAddreaa = destinationGateAddrea;
        this.symbol = symbol;
        
    }

    // function to call the axelarGate to send tokens to L1
    function sendTokensToL1(string memory destinationChain, string memory symbol) public {

        byte memory payload =         
        IAxelarGater(axelarGate).callContractWithToken(destinationChain, l1GateAddress, payload, symbol, getITokensToInvest());
    }

    // function to get the iToken balance of the gate
    // this is the amount of tokens that have been deposited
    // by users and are waiting to be sent to L1
    function getITokensToInvest() public view returns(uint256){
        return IERC20(iTokenAddress).balanceOf(address(this));
    }

}