// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Core multisig wallet functionality with timelock

contract MultisigCore {
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public threshold;
    uint256 public constant TIMELOCK_DURATION = 1 hours;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "no owners");
        require(_threshold > 0 && _threshold <= _owners.length, "invalid threshold");
        
        threshold = _threshold;
        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }
    }

    function submitTransaction(address to, uint256 value, bytes memory data) 
        public 
        onlyOwner 
    {
        uint256 txId = transactionCount++;
        transactions[txId] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[txId][msg.sender] = true;
        emit Submission(txId);
    }

    function confirmTransaction(uint256 txId) external onlyOwner {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "already executed");
        require(!confirmed[txId][msg.sender], "already confirmed");
        
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        
        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, "insufficient confirmations");
        require(!txn.executed, "already executed");
        require(block.timestamp >= txn.executionTime, "timelock not expired");
        
        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "execution failed");
        
        emit Execution(txId);
    }

    function getTransaction(uint256 txId) 
        external 
        view 
        returns (Transaction memory) 
    {
        return transactions[txId];
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }
}
