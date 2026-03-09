// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Merkle tree-based airdrop distribution

abstract contract MerkleAirdrop {
    
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    event MerkleRootSet(bytes32 indexed newRoot, address indexed setter);
    event Claim(address indexed claimant, uint256 amount);

    function _setMerkleRoot(bytes32 root) internal {
        require(root != bytes32(0), "invalid root");
        merkleRoot = root;
        emit MerkleRootSet(root, msg.sender);
    }

    function _processClaim(bytes32[] calldata proof, uint256 amount) internal {
        require(amount > 0, "invalid amount");
        require(!claimed[msg.sender], "already claimed");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "invalid proof");
        
        claimed[msg.sender] = true;
        emit Claim(msg.sender, amount);
    }

    function hasClaimed(address user) external view virtual returns (bool) {
        return claimed[user];
    }

    function verifyProof(bytes32[] calldata proof, address user, uint256 amount) 
        external 
        view 
        returns (bool) 
    {
        bytes32 leaf = keccak256(abi.encodePacked(user, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
