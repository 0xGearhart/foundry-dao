// SPDX-License-Identifier: MIT

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.27;

contract SimpleStorage is Ownable {
    uint256 private s_number;

    event NumberChanged(uint256 indexed newNumber);

    constructor(address owner) Ownable(owner) {}

    function changeNumber(uint256 newNumber) external onlyOwner {
        s_number = newNumber;
        emit NumberChanged(newNumber);
    }

    function getNumber() external view returns (uint256) {
        return s_number;
    }
}
