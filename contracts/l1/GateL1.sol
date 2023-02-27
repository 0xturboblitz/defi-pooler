// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IAxelarExecutable} from "../interfaces/IAxelarExecutable.sol";
import {IAxelarGateway} from "../interfaces/IAxelarGateway.sol";


contract GateL1 is IAxelarExecutable {

    address public axelarGateway;
    string public destinationChain;
    string public l2GateAddress;
    string public symbol;
    address public iTokenAddress;
    address public pTokenAddress;
    
    constructor(address _axelarGateway, string memory _destinationChain, string memory _l2GateAddress, string memory _symbol, address _iTokenAddress, address _pTokenAddress) {
        axelarGateway = _axelarGateway;
        destinationChain = _destinationChain;
        l2GateAddress = _l2GateAddress;
        symbol = _symbol;
        iTokenAddress = _iTokenAddress;
        pTokenAddress = _pTokenAddress;
    }

    

}
