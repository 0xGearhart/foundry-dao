// SPDX-License-Identifier: MIT

import {CodeConstants} from "../../script/HelperConfig.s.sol";
import {DaoToken} from "../../src/DaoToken.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Test, console} from "forge-std/Test.sol";

pragma solidity ^0.8.27;

contract DaoTokenTest is Test, CodeConstants {
    DaoToken public daoToken;

    address user = makeAddr("user");
    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // ANVIL_DEFAULT_ACCOUNT
    uint256 constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant PERMIT_AMOUNT = 100 ether;
    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function setUp() public {
        daoToken = new DaoToken(owner, TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
    }

    function testDelegateTokenVotingPower() public {
        vm.prank(owner);
        daoToken.delegate(user);
        assertEq(daoToken.delegates(owner), user);
    }

    function testClock() public view {
        assertEq(daoToken.clock(), block.timestamp);
    }

    function testNonces() public {
        assertEq(daoToken.nonces(owner), 0);
        uint256 deadline = block.timestamp + 10;

        bytes32 structHash =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, user, PERMIT_AMOUNT, daoToken.nonces(owner), deadline));
        bytes32 digest = MessageHashUtils.toTypedDataHash(daoToken.DOMAIN_SEPARATOR(), structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ANVIL_DEFAULT_KEY, digest);

        vm.prank(owner);
        daoToken.permit(owner, user, PERMIT_AMOUNT, deadline, v, r, s);
        assertEq(daoToken.nonces(owner), 1);
    }

    function testClockMode() public view {
        assertEq(daoToken.CLOCK_MODE(), "mode=timestamp");
    }
}
