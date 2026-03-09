// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Signature verification utilities

abstract contract SignatureUtils {
    
    function _recoverSigner(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 prefixedHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        return ecrecover(prefixedHash, v, r, s);
    }

    function _hashMessage(string memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(message));
    }

    function _hashStructure(bytes memory data) internal pure returns (bytes32) {
        return keccak256(data);
    }

    function verifySignature(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address expectedSigner
    ) public pure returns (bool) {
        return _recoverSigner(messageHash, v, r, s) == expectedSigner;
    }
}
