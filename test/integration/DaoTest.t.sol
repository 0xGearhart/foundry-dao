// SPDX-License-Identifier: MIT

import {DeployDao} from "../../script/DeployDao.s.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";
import {DaoGovernor, GovernorCountingSimple, IGovernor} from "../../src/DaoGovernor.sol";
import {DaoStorage, Ownable} from "../../src/DaoStorage.sol";
import {DaoTimeLock} from "../../src/DaoTimeLock.sol";
import {DaoToken} from "../../src/DaoToken.sol";
import {Test} from "forge-std/Test.sol";

pragma solidity ^0.8.27;

contract DaoTest is Test, CodeConstants {
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    DeployDao public deployDao;
    DaoGovernor public daoGovernor;
    DaoToken public daoToken;
    DaoStorage public daoStorage;
    DaoTimeLock public daoTimeLock;

    uint256 newNumber = 42;
    address user = makeAddr("user");
    address voter = makeAddr("voter");
    address tokenHolder = DEFAULT_SENDER;
    uint256 constant VOTER_BALANCE_QUORUM = 100 ether;

    address[] targetsArray;
    uint256[] valuesArray;
    bytes[] calldatasArray;
    bytes encodedFunctionCall = abi.encodeWithSignature("changeNumber(uint256)", newNumber);
    string description = "update number to 42";

    modifier getTokensAndSelfDelegate() {
        // send enough tokens to meet quorum to voter
        vm.prank(tokenHolder);
        bool success = daoToken.transfer(voter, VOTER_BALANCE_QUORUM);
        success;
        assertEq(daoToken.balanceOf(voter), VOTER_BALANCE_QUORUM);
        // delegate voting power to themselves
        vm.prank(voter);
        daoToken.delegate(voter);
        assertEq(daoToken.delegates(voter), voter);
        _;
    }

    function setUp() public {
        deployDao = new DeployDao();
        (daoTimeLock, daoGovernor, daoToken, daoStorage) = deployDao.run();
    }

    function testCanNotUpdateDaoStorageWithoutGovernance() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, tokenHolder));
        vm.prank(tokenHolder);
        daoStorage.changeNumber(newNumber);
    }

    function testAnyoneCanSubmitProposalToDaoGovernor() public {
        // proposal data using memory
        address[] memory targets = new address[](1);
        targets[0] = address(daoStorage);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = encodedFunctionCall;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        // dummy array for event
        string[] memory signatures = new string[](1);
        signatures[0] = "";
        // expect event emitted by daoGovernor but ignore all values within event
        vm.expectEmit(false, false, false, false, address(daoGovernor));
        emit ProposalCreated(0, address(this), targets, values, signatures, calldatas, 0, 0, description);
        // prank as account with no tokens
        vm.prank(user);
        uint256 proposalId = daoGovernor.propose(targets, values, calldatas, description);
        // check state after submission
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Pending);
    }

    function testGovernanceCanUpdateDaoStorageFullTest() public getTokensAndSelfDelegate {
        // another way of loading proposal data using storage
        targetsArray.push(address(daoStorage));
        valuesArray.push(0);
        calldatasArray.push(encodedFunctionCall);

        // 1. Send proposal to the DAO
        uint256 proposalId = daoGovernor.propose(targetsArray, valuesArray, calldatasArray, description);

        // enum ProposalState {
        //     Pending, = 0
        //     Active, = 1
        //     Canceled, = 2
        //     Defeated, = 3
        //     Succeeded, = 4
        //     Queued, = 5
        //     Expired, = 6
        //     Executed = 7
        // }

        // check state after submission
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Pending);
        // advance time
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        // check state after voting delay has passed
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Active);

        // 2. Vote on proposal
        string memory reason = "The answer to life, the universe, and everything";

        // enum VoteType {
        //     Against, = 0
        //     For, = 1
        //     Abstain = 2
        // }

        uint8 vote = uint8(GovernorCountingSimple.VoteType.For);
        vm.prank(voter);
        daoGovernor.castVoteWithReason(proposalId, vote, reason);
        // advance time to end of voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        // check voting state
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Succeeded);

        // TODO: look into this, maybe just add the logic into the overriding function
        assertEq(daoGovernor.proposalNeedsQueuing(proposalId), true); // seems to always return true??? the inherited parent functions either hardcode false or true, no logic to determine which should be returned

        // 3. Queue successful proposal
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        daoGovernor.queue(targetsArray, valuesArray, calldatasArray, descriptionHash);
        // check voting state
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Queued);
        // advance time until minimum delay has passed, then proposal can be executed
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        // 4. Execute proposal
        daoGovernor.execute(targetsArray, valuesArray, calldatasArray, descriptionHash);
        // verify proposal state
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Executed);

        // TODO: look into this
        // assertEq(daoGovernor.proposalNeedsQueuing(proposalId), false); // this should return false since its already executed and no longer needs to be queued

        // verify daoStorage after execution
        assertEq(daoStorage.getNumber(), newNumber);
    }

    function testCancelProposalAfterSubmission() public {
        targetsArray.push(address(daoStorage));
        valuesArray.push(0);
        calldatasArray.push(encodedFunctionCall);

        // 1. Send proposal to the DAO
        uint256 proposalId = daoGovernor.propose(targetsArray, valuesArray, calldatasArray, description);
        // check state after submission
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Pending);

        // 2. Cancel proposal
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        daoGovernor.cancel(targetsArray, valuesArray, calldatasArray, descriptionHash);
        // check state after cancellation
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Canceled);
    }

    function testProposalDefeatedAfterNoVote() public getTokensAndSelfDelegate {
        targetsArray.push(address(daoStorage));
        valuesArray.push(0);
        calldatasArray.push(encodedFunctionCall);

        // 1. Send proposal to the DAO
        uint256 proposalId = daoGovernor.propose(targetsArray, valuesArray, calldatasArray, description);
        // check state after submission
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Pending);
        // advance time
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        // check state after voting delay has passed
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Active);

        // 2. Vote on proposal
        string memory reason = "No way";
        uint8 vote = uint8(GovernorCountingSimple.VoteType.Against);
        vm.prank(voter);
        daoGovernor.castVoteWithReason(proposalId, vote, reason);
        // advance time to end of voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        // check state after cancellation
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Defeated);
    }

    // TODO: look into how a proposal can expire, thought it would be no votes after period passed but that just means defeated
    function testProposalDefeatedAfterNoQuorum() public {
        targetsArray.push(address(daoStorage));
        valuesArray.push(0);
        calldatasArray.push(encodedFunctionCall);

        // 1. Send proposal to the DAO
        uint256 proposalId = daoGovernor.propose(targetsArray, valuesArray, calldatasArray, description);
        // check state after submission
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Pending);
        // advance time
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        // check state after voting delay has passed
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Active);

        // 2. Let proposal expire
        // advance time to end of voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        // check state after cancellation
        assert(daoGovernor.state(proposalId) == IGovernor.ProposalState.Defeated);
    }
}
