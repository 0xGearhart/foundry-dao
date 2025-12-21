// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    constructor(
        uint256 minDelay, // how long you have to wait before executing
        address[] memory proposers, // list of addresses that can propose
        address[] memory executors, // list of addresses that can execute
        address admin
    )
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
