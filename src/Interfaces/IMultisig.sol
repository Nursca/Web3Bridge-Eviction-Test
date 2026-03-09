// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for multisig transaction management

interface IMultisig {
    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    function submitTransaction(address to, uint256 value, bytes memory data) external;
    function confirmTransaction(uint256 txId) external;
    function executeTransaction(uint256 txId) external;
    function isOwner(address account) external view returns (bool);
}