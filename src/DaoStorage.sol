// SPDX-License-Identifier: MIT

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.27;

/**
 * @title DaoStorage
 * @author Gearhart
 * @notice Simple storage contract to be owned and governed by the DAO.
 * @dev Needs to be owned by DaoTimeLock contract to prevent the DAO from executing proposals without minimum delay.
 */
contract DaoStorage is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    uint256 private s_number;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event NumberChanged(uint256 indexed newNumber);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address owner) Ownable(owner) {}

    /**
     * @notice Allows owner to change number saved to storage
     * @param newNumber new number to be saved to contract storage
     * @dev only callable by owner
     */
    function changeNumber(uint256 newNumber) external onlyOwner {
        s_number = newNumber;
        emit NumberChanged(newNumber);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Gets number from storage
     * @return number currently saved to contract storage
     */
    function getNumber() external view returns (uint256) {
        return s_number;
    }
}
