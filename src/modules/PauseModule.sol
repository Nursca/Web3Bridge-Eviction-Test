// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Pause functionality with access control

abstract contract PauseModule {
    
    bool public paused;

    event Paused(address indexed by);
    event Unpaused(address indexed by);

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "not paused");
        _;
    }

    function _pause() internal {
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function isPaused() external view returns (bool) {
        return paused;
    }
}
