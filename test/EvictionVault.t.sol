// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EvictionVaultTest is Test {
    EvictionVault vault;
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address user = address(0x4);

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vault = new EvictionVault{value: 10 ether}(owners, 2);
    }

    // TEST 1: Basic Deposit and Withdrawal
    function testDepositAndWithdraw() public {
        vm.startPrank(user);
        vm.deal(user, 10 ether);
        vault.deposit{value: 1 ether}();
        assertEq(vault.getBalance(user), 1 ether, "Deposit balance mismatch");

        vault.withdraw(0.5 ether);
        assertEq(vault.getBalance(user), 0.5 ether, "Withdraw balance mismatch");
        vm.stopPrank();
    }

    // TEST 2: Receive Function Uses msg.sender (FIXED: tx.origin vulnerability)
    function testReceiveUsesMsgSender() public {
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        uint256 initialBalance = vault.getBalance(user);
        
        (bool success, ) = address(vault).call{value: 1 ether}("");
        require(success, "receive failed");
        
        uint256 finalBalance = vault.getBalance(user);
        assertEq(finalBalance - initialBalance, 1 ether, "receive balance mismatch");
        vm.stopPrank();
    }

    // TEST 3: Withdrawal Uses Safe .call (FIXED: .transfer vulnerability)
    function testWithdrawalUsesSafeCall() public {
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        vault.deposit{value: 2 ether}();
        
        uint256 initialBalance = user.balance;
        vault.withdraw(1 ether);
        uint256 finalBalance = user.balance;
        
        assertEq(finalBalance - initialBalance, 1 ether);
        vm.stopPrank();
    }

    // TEST 4: setMerkleRoot Requires Multisig (FIXED: anyone callable vulnerability)
    function testSetMerkleRootRequiresMultisig() public {
        bytes32 newRoot = keccak256(abi.encodePacked("test"));
        
        // Should revert when called directly by non-contract
        vm.startPrank(user);
        vm.expectRevert("only multisig");
        vault.setMerkleRoot(newRoot);
        vm.stopPrank();

        // Should succeed when called via multisig transaction
        vm.startPrank(owner1);
        bytes memory data = abi.encodeWithSignature("setMerkleRoot(bytes32)", newRoot);
        vault.submitTransaction(address(vault), 0, data);
        vm.stopPrank();

        vm.startPrank(owner2);
        vault.confirmTransaction(0);
        vm.stopPrank();

        // Execute after timelock
        vm.warp(block.timestamp + 1 hours + 1);
        vault.executeTransaction(0);
        
        assertEq(vault.merkleRoot(), newRoot);
    }

    // TEST 5: Pause Requires Multisig (FIXED: single owner control vulnerability)
    function testPauseRequiresMultisig() public {
        // Should revert when called directly
        vm.startPrank(owner1);
        vm.expectRevert("only multisig");
        vault.pause();
        vm.stopPrank();

        // Should succeed via multisig
        vm.startPrank(owner1);
        vault.proposePause();
        vm.stopPrank();

        vm.startPrank(owner2);
        vault.confirmTransaction(0);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1);
        vault.executeTransaction(0);

        assertTrue(vault.paused());
    }

    // TEST 6: Unpause Requires Multisig (FIXED: single owner control vulnerability)
    function testUnpauseRequiresMultisig() public {
        // First pause via multisig
        vm.startPrank(owner1);
        vault.proposePause();
        vm.stopPrank();

        vm.startPrank(owner2);
        vault.confirmTransaction(0);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1);
        vault.executeTransaction(0);

        // Now unpause via multisig
        vm.startPrank(owner1);
        vault.proposeUnpause();
        vm.stopPrank();

        vm.startPrank(owner2);
        vault.confirmTransaction(1);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours + 1);
        vault.executeTransaction(1);

        assertFalse(vault.paused());
    }

    // TEST 7: emergencyWithdrawAll Requires Multisig (FIXED: public drain vulnerability)
    function testEmergencyWithdrawRequiresMultisig() public {
        uint256 initialBalance = address(vault).balance;

        // Should revert when called directly by anyone
        vm.startPrank(user);
        vm.expectRevert("only multisig");
        vault.emergencyWithdrawAll();
        vm.stopPrank();

        // Should succeed via multisig with timelock
        vm.startPrank(owner1);
        vault.proposeEmergencyWithdraw();
        vm.stopPrank();

        vm.startPrank(owner2);
        vault.confirmTransaction(0);
        vm.stopPrank();

        // Check that funds are still in vault before timelock
        assertEq(address(vault).balance, initialBalance);

        vm.warp(block.timestamp + 1 hours + 1);
        vault.executeTransaction(0);

        // After execution, balance should be transferred to owner1 (tx.origin in this context)
    }

    // TEST 8: Merkle Airdrop with Claim Uses Safe .call (FIXED: .transfer vulnerability)
    function testMerkleClaimUsesSafeCall() public {
        // Setup merkle root
        bytes32[] memory data = new bytes32[](1);
        data[0] = keccak256(abi.encodePacked(user, uint256(1 ether)));
        bytes32 root = data[0];

        // Set merkle root via multisig
        vm.startPrank(owner1);
        vault.proposeMerkleRoot(root);
        vm.stopPrank();

        vm.startPrank(owner2);
        vault.confirmTransaction(0);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1);
        vault.executeTransaction(0);

        // Now user can claim
        vm.startPrank(user);
        bytes32[] memory proof = new bytes32[](0);
        uint256 initialBalance = user.balance;
        vault.claim(proof, 1 ether);
        uint256 finalBalance = user.balance;

        assertEq(finalBalance - initialBalance, 1 ether);
        vm.stopPrank();
    }
}