// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// This is a smart contract called Migrations.
contract Migrations {
    // The public address variable owner will be accessible to everyone.
    address public owner;
    
    // The public uint256 variable last_completed_migration will also be accessible to everyone.
    uint256 public last_completed_migration;

    // The constructor function sets the owner of the contract to the address of the person who deployed it.
    // This function is executed only once, during the contract deployment.
    constructor() {
        owner = msg.sender;
    }

    // The restricted modifier checks if the caller is the owner of the contract.
    // If the caller is the owner, then the function execution is allowed.
    modifier restricted() {
        if (msg.sender == owner) _;
    }

    // The setCompleted function sets the last_completed_migration variable to the value passed as an argument.
    // This function can only be executed by the owner of the contract.
    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }

    // The upgrade function deploys a new instance of the Migrations contract at the new address
    // and sets the value of last_completed_migration to the value of the previous instance.
    // This function can only be executed by the owner of the contract.
    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}
