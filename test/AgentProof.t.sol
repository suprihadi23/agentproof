// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AgentProof} from "../contracts/AgentProof.sol";

interface Vm {
    function warp(uint256 newTimestamp) external;
    function prank(address msgSender) external;
}

contract MockAgentID {
    mapping(address => uint256) public balanceOf;
    function set(address who, uint256 amount) external { balanceOf[who] = amount; }
}

contract AgentProofTest {
    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    MockAgentID registry;
    AgentProof proof;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA401); // no Agent ID

    function setUp() public {
        registry = new MockAgentID();
        proof = new AgentProof(address(registry));
        registry.set(alice, 1);
        registry.set(bob, 1);
        vm.warp(1_800_000_000); // fixed start time
    }

    // ------------------------------------------------------------- helpers
    function assertEq(uint256 a, uint256 b, string memory m) internal pure {
        require(a == b, m);
    }
    function assertTrue(bool c, string memory m) internal pure {
        require(c, m);
    }

    // --------------------------------------------------------------- tests

    function testNonHolderCannotCheckIn() public {
        vm.prank(carol);
        try proof.checkIn() {
            revert("expected revert");
        } catch Error(string memory reason) {
            assertTrue(keccak256(bytes(reason)) == keccak256(bytes("AgentProof: no Agent ID")), "wrong reason");
        }
    }

    function testCheckInAutoRegistersAndPoints() public {
        vm.prank(alice);
        proof.checkIn();
        (bool reg, , , uint32 streak, , uint32 count, uint256 points, ) = proof.getProfile(alice);
        assertTrue(reg, "registered");
        assertEq(streak, 1, "streak 1");
        assertEq(count, 1, "1 checkin");
        assertEq(points, 11, "10 base + 1 streak bonus");
        assertEq(proof.totalAgents(), 1, "totalAgents");
        assertEq(proof.totalCheckIns(), 1, "totalCheckIns");
    }

    function testDoubleCheckInSameDayReverts() public {
        vm.prank(alice);
        proof.checkIn();
        vm.prank(alice);
        try proof.checkIn() {
            revert("expected revert");
        } catch Error(string memory reason) {
            assertTrue(keccak256(bytes(reason)) == keccak256(bytes("AgentProof: already checked in today")), "wrong reason");
        }
    }

    function testStreakContinuesNextDayAndResetsAfterGap() public {
        vm.prank(alice);
        proof.checkIn(); // day N, streak 1, +11
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        proof.checkIn(); // streak 2, +12
        (, , , uint32 streak, uint32 best, , uint256 points, ) = proof.getProfile(alice);
        assertEq(streak, 2, "streak 2");
        assertEq(best, 2, "best 2");
        assertEq(points, 23, "11 + 12");

        vm.warp(block.timestamp + 2 days); // skip a day
        vm.prank(alice);
        proof.checkIn(); // streak resets to 1, +11
        (, , , uint32 streak2, uint32 best2, , uint256 points2, ) = proof.getProfile(alice);
        assertEq(streak2, 1, "streak reset");
        assertEq(best2, 2, "best kept");
        assertEq(points2, 34, "23 + 11");
    }

    function testRegisterAndUpdateCard() public {
        vm.prank(alice);
        proof.register("ipfs://card-alice");
        (, , , , , , , string memory uri) = proof.getProfile(alice);
        assertTrue(keccak256(bytes(uri)) == keccak256(bytes("ipfs://card-alice")), "uri set");
        vm.prank(alice);
        proof.register("ipfs://card-alice-v2");
        (, , , , , , , string memory uri2) = proof.getProfile(alice);
        assertTrue(keccak256(bytes(uri2)) == keccak256(bytes("ipfs://card-alice-v2")), "uri updated");
        assertEq(proof.totalAgents(), 1, "still one agent");
    }

    function testEndorseFlow() public {
        bytes32 tag = keccak256("trading");
        vm.prank(alice);
        proof.register("");
        vm.prank(bob);
        proof.endorse(alice, tag);
        assertEq(proof.endorsementCountByTag(alice, tag), 1, "tag count");
        assertEq(proof.totalEndorsementsReceived(alice), 1, "total received");
        (, , , , , , uint256 points, ) = proof.getProfile(alice);
        assertEq(points, 5, "endorsee +5 points");
        // duplicate endorsement reverts
        vm.prank(bob);
        try proof.endorse(alice, tag) {
            revert("expected revert");
        } catch Error(string memory reason) {
            assertTrue(keccak256(bytes(reason)) == keccak256(bytes("AgentProof: already endorsed")), "wrong reason");
        }
    }

    function testSelfEndorseReverts() public {
        vm.prank(alice);
        proof.register("");
        vm.prank(alice);
        try proof.endorse(alice, keccak256("coding")) {
            revert("expected revert");
        } catch Error(string memory reason) {
            assertTrue(keccak256(bytes(reason)) == keccak256(bytes("AgentProof: self endorsement")), "wrong reason");
        }
    }

    function testEndorseUnregisteredReverts() public {
        vm.prank(bob);
        try proof.endorse(alice, keccak256("coding")) {
            revert("expected revert");
        } catch Error(string memory reason) {
            assertTrue(keccak256(bytes(reason)) == keccak256(bytes("AgentProof: agent not registered")), "wrong reason");
        }
    }

    function testPauseBlocksAndOwnerOnly() public {
        proof.setPaused(true);
        vm.prank(alice);
        try proof.checkIn() {
            revert("expected revert");
        } catch Error(string memory reason) {
            assertTrue(keccak256(bytes(reason)) == keccak256(bytes("AgentProof: paused")), "wrong reason");
        }
        vm.prank(alice);
        try proof.setPaused(false) {
            revert("expected revert");
        } catch Error(string memory reason) {
            assertTrue(keccak256(bytes(reason)) == keccak256(bytes("AgentProof: not owner")), "wrong reason");
        }
    }

    function testCheckedInToday() public {
        assertTrue(!proof.checkedInToday(alice), "not yet");
        vm.prank(alice);
        proof.checkIn();
        assertTrue(proof.checkedInToday(alice), "checked in");
    }
}
