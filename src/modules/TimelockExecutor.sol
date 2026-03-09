// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Generic timelock functionality for delayed execution

abstract contract TimelockExecutor {
    
    uint256 public immutable TIMELOCK_DURATION;

    mapping(bytes32 => uint256) public timelocks;

    event TimelockStarted(bytes32 indexed id, uint256 targetTime);
    event TimelockExecuted(bytes32 indexed id);

    constructor(uint256 _timelockDuration) {
        require(_timelockDuration > 0, "invalid timelock");
        TIMELOCK_DURATION = _timelockDuration;
    }

    function _startTimelock(bytes32 id) internal {
        timelocks[id] = block.timestamp + TIMELOCK_DURATION;
        emit TimelockStarted(id, timelocks[id]);
    }

    function _requireTimelockExpired(bytes32 id) internal view {
        require(block.timestamp >= timelocks[id], "timelock not expired");
    }

    function _executeTimelock(bytes32 id) internal {
        _requireTimelockExpired(id);
        delete timelocks[id];
        emit TimelockExecuted(id);
    }

    function getTimelockTime(bytes32 id) external view returns (uint256) {
        return timelocks[id];
    }

    function isTimelockExpired(bytes32 id) external view returns (bool) {
        return timelocks[id] > 0 && block.timestamp >= timelocks[id];
    }
}
