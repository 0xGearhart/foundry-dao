// SPDX-License-Identifier: MIT

import {DeployDao} from "../../script/DeployDao.s.sol";
import {CodeConstants, HelperConfig} from "../../script/HelperConfig.s.sol";
import {DaoGovernor} from "../../src/DaoGovernor.sol";
import {DaoStorage} from "../../src/DaoStorage.sol";
import {DaoTimeLock} from "../../src/DaoTimeLock.sol";
import {DaoToken} from "../../src/DaoToken.sol";
import {Test} from "forge-std/Test.sol";

pragma solidity ^0.8.27;

contract DaoTest is Test, CodeConstants {
    DeployDao public deployDao;
    DaoGovernor public daoGovernor;
    DaoToken public daoToken;
    DaoStorage public daoStorage;
    DaoTimeLock public daoTimeLock;

    function setUp() public {
        deployDao = new DeployDao();
        (daoTimeLock, daoGovernor, daoToken, daoStorage) = deployDao.run();
    }

    function testHelperConfigReturnsCorrectAccountOnForkedChain() public {
        vm.createSelectFork(vm.envString("ARB_SEPOLIA_RPC_URL"));
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig();
        assertEq(config.account, vm.envAddress("DEFAULT_KEY_ADDRESS"));
    }

    function testDaoTimeLockSetUpCorrectly() public view {
        assert(daoTimeLock.hasRole(daoTimeLock.PROPOSER_ROLE(), address(daoGovernor)));
        assert(daoTimeLock.hasRole(daoTimeLock.EXECUTOR_ROLE(), address(0)));
        assert(!daoTimeLock.hasRole(daoTimeLock.DEFAULT_ADMIN_ROLE(), DEFAULT_SENDER));
    }

    function testDaoGovernorSetUpCorrectly() public view {
        assertEq(daoGovernor.name(), GOVERNOR_NAME);
        assertEq(daoGovernor.votingDelay(), VOTING_DELAY);
        assertEq(daoGovernor.votingPeriod(), VOTING_PERIOD);
        assertEq(daoGovernor.proposalThreshold(), PROPOSAL_VOTING_THRESHOLD);
        assertEq(daoGovernor.quorumNumerator(), QUORUM_NUMERATOR_VALUE);
        assertEq(address(daoGovernor.token()), address(daoToken));
        assertEq(daoGovernor.timelock(), address(daoTimeLock));
    }

    function testDaoTokenSetUpCorrectly() public view {
        assertEq(daoToken.balanceOf(DEFAULT_SENDER), INITIAL_SUPPLY);
        assertEq(daoToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(daoToken.name(), TOKEN_NAME);
        assertEq(daoToken.symbol(), TOKEN_SYMBOL);
    }

    function testDaoStorageSetUpCorrectly() public view {
        assertEq(daoStorage.owner(), address(daoTimeLock));
    }
}
