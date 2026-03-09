// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for merkle tree-based airdrops

interface IAirdrop {
    function setMerkleRoot(bytes32 root) external;
    function claim(bytes32[] calldata proof, uint256 amount) external;
    function hasClaimed(address user) external view returns (bool);
}
