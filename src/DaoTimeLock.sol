// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title DaoTimeLock
 * @author Gearhart
 * @notice Time lock contract to ensure a minimum amount of time passes before any successful proposal is executed.
 * This allows unsatisfied holders sufficient time to leave the DAO before proposal execution. Ensures all
 * proposals are sent from the DAO. Permits any address to execute valid proposals after required delay has passed.
 * @dev Compatible with OpenZeppelin Contracts ^5.5.0
 */
contract DaoTimeLock is TimelockController {
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        uint256 minDelay, // how long you have to wait before executing
        address[] memory proposers, // list of addresses that can propose
        address[] memory executors, // list of addresses that can execute
        address admin // address to grant administrator role to
    )
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
