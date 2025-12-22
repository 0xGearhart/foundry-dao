// SPDX-License-Identifier: MIT

import {DaoStorage, Ownable} from "../../src/DaoStorage.sol";
import {Test} from "forge-std/Test.sol";

pragma solidity ^0.8.27;

contract DaoStorageTest is Test {
    event NumberChanged(uint256 indexed newNumber);

    DaoStorage public daoStorage;

    uint256 newNumber = 42;
    address user = makeAddr("user");
    address owner = DEFAULT_SENDER;

    function setUp() public {
        daoStorage = new DaoStorage(owner);
    }

    function testNonOwnerCanNotChangeNumber() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vm.prank(user);
        daoStorage.changeNumber(newNumber);
    }

    function testOwnerCanChangeNumber() public {
        assertEq(daoStorage.getNumber(), 0);
        vm.expectEmit(true, false, false, false, address(daoStorage));
        emit NumberChanged(newNumber);
        vm.prank(owner);
        daoStorage.changeNumber(newNumber);
        assertEq(daoStorage.getNumber(), newNumber);
    }
}
