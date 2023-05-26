// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

contract Ownable {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        // if the above condition is satisfied while calling this function,
        // the caller fuction is executed and otherwise, an exception is thrown
        _;

        /**
        require(msg.sender == owner);
        _;

        --> call 2 times the body in the caller function
         */
    }
}
