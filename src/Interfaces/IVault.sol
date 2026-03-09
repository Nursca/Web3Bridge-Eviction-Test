// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for vault deposit/withdrawal functionality

interface IVault {
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getBalance(address user) external view returns (uint256);
}