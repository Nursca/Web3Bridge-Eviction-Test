// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./modules/MultisigCore.sol";
import "./modules/PauseModule.sol";
import "./modules/MerkleAirdrop.sol";
import "./Interfaces/IVault.sol";
import "./Interfaces/IAirdrop.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Secure vault with multisig control, merkle airdrops, and timelock execution

/* 
 * Fixed Contract Vunabilities:
 * - setMerkleRoot Callable by Anyone
 * - emergencyWithdrawAll Public Drain
 * - pause/unpause Single Owner Control
 * - receive() Uses tx.origin
 * - withdraw & claim Uses .transfer
 * - Timelock Execution
 */
contract EvictionVault is MultisigCore, PauseModule, MerkleAirdrop, IVault, IAirdrop {
    
    mapping(address => uint256) public balances;
    uint256 public totalVaultValue;

    bytes32 public constant PAUSE_OPERATION = keccak256("PAUSE");
    bytes32 public constant UNPAUSE_OPERATION = keccak256("UNPAUSE");
    bytes32 public constant MERKLE_ROOT_OPERATION = keccak256("MERKLE_ROOT");
    bytes32 public constant EMERGENCY_WITHDRAW_OPERATION = keccak256("EMERGENCY_WITHDRAW");

    mapping(bytes32 => bool) private operationExecuted;

    event EmergencyWithdrawInitiated(address indexed initiator, uint256 txId);
    event EmergencyWithdrawExecuted(uint256 amount);

    constructor(address[] memory _owners, uint256 _threshold) payable 
        MultisigCore(_owners, _threshold) 
    {
        totalVaultValue = msg.value;
    }

    // FIXED: receive uses msg.sender instead of tx.origin

    receive() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Deposit ETH into vault

    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "no value");
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // FIXED: withdraw function uses safe .call instead of .transfer to avoid gas issues

    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "invalid amount");
        require(balances[msg.sender] >= amount, "insufficient balance");
        
        balances[msg.sender] -= amount;
        totalVaultValue -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }

    // FIXED: setMerkleRoot callable by anyone, only callable via multisig transaction

    function setMerkleRoot(bytes32 root) external override {
        require(msg.sender == address(this), "only multisig");
        _setMerkleRoot(root);
    }

    // FIXED: claim function uses safe .call instead of .transfer

    function claim(bytes32[] calldata proof, uint256 amount) 
        external 
        override
        whenNotPaused 
    {
        require(amount > 0, "invalid amount");
        require(address(this).balance >= amount, "insufficient vault funds");
        
        _processClaim(proof, amount);
        
        totalVaultValue -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "transfer failed");
    }

    // FIXED: pause function single owner control, only callable via multisig transaction

    function pause() external {
        require(msg.sender == address(this), "only multisig");
        _pause();
    }

    // FIXED: unpause function single owner control, only callable via multisig transaction

    function unpause() external {
        require(msg.sender == address(this), "only multisig");
        _unpause();
    }

    // FIXED: emergencyWithdrawAll public drain, requires multisig approval and timelock, not callable by anyone
 
    function emergencyWithdrawAll() external {
        require(msg.sender == address(this), "only multisig");
        uint256 balance = address(this).balance;
        totalVaultValue = 0;
        
        (bool success, ) = payable(tx.origin).call{value: balance}("");
        require(success, "transfer failed");
        
        emit EmergencyWithdrawExecuted(balance);
    }

    // Helper function to prepare merkle root update transaction
    
    function proposeMerkleRoot(bytes32 root) external onlyOwner {
        bytes memory data = abi.encodeWithSignature("setMerkleRoot(bytes32)", root);
        submitTransaction(address(this), 0, data);
    }

    // Helper function to prepare pause transaction
    
    function proposePause() external onlyOwner {
        bytes memory data = abi.encodeWithSignature("pause()");
        submitTransaction(address(this), 0, data);
    }

    // Helper function to prepare unpause transaction
    
    function proposeUnpause() external onlyOwner {
        bytes memory data = abi.encodeWithSignature("unpause()");
        submitTransaction(address(this), 0, data);
    }

    // Helper function to prepare emergency withdraw transaction
    
    function proposeEmergencyWithdraw() external onlyOwner {
        bytes memory data = abi.encodeWithSignature("emergencyWithdrawAll()");
        submitTransaction(address(this), 0, data);
    }

    function getBalance(address user) external view override returns (uint256) {
        return balances[user];
    }

    function hasClaimed(address user) external view override(IAirdrop, MerkleAirdrop) returns (bool) {
        return claimed[user];
    }

    function getTotalVaultValue() external view returns (uint256) {
        return totalVaultValue;
    }
}