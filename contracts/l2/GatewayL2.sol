// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./interfaces/IAxelarGateway.sol";

contract Gateway {

    address axelarGate; 

    constructor(address axelarGate){
        axelarGate = axelarGate;
    }

}