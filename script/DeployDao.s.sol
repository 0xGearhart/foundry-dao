// SPDX-License-Identifier: MIT

import {DaoGovernor} from "../src/DaoGovernor.sol";
import {DaoStorage} from "../src/DaoStorage.sol";
import {DaoTimeLock} from "../src/DaoTimeLock.sol";
import {DaoToken} from "../src/DaoToken.sol";
import {CodeConstants, HelperConfig} from "./HelperConfig.s.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Script} from "forge-std/Script.sol";

pragma solidity ^0.8.27;

contract DeployDao is Script, CodeConstants {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    address[] public proposers;
    address[] public executors;

    function run()
        external
        returns (DaoTimeLock daoTimeLock, DaoGovernor daoGovernor, DaoToken daoToken, DaoStorage daoStorage)
    {
        // get config
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.startBroadcast(config.account);
        // deploy contracts
        daoToken = new DaoToken(config.account, TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
        daoTimeLock = new DaoTimeLock(MIN_DELAY, proposers, executors, config.account);
        daoGovernor = new DaoGovernor(
            GOVERNOR_NAME,
            VOTING_DELAY,
            VOTING_PERIOD,
            PROPOSAL_VOTING_THRESHOLD,
            QUORUM_NUMERATOR_VALUE,
            IVotes(daoToken),
            daoTimeLock
        );
        daoStorage = new DaoStorage(address(daoTimeLock)); // time lock needs to own or else dao could call without time lock restrictions

        // setup roles and renounce admin
        daoTimeLock.grantRole(PROPOSER_ROLE, address(daoGovernor)); // only dao can propose actions to time lock
        daoTimeLock.grantRole(EXECUTOR_ROLE, address(0)); // grant to address 0 to allow anyone to execute passed proposals
        daoTimeLock.renounceRole(DEFAULT_ADMIN_ROLE, config.account); // renounce role to remove centralization risk
        vm.stopBroadcast();
    }
}
