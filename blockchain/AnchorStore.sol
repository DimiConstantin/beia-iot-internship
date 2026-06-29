// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnchorStore {
    struct Anchor {
        bytes32 dataHash;
        uint256 timestamp;
    }

    mapping(uint256 => Anchor) public anchors;
    uint256 public batchCount;

    event Anchored(uint256 indexed batchId, bytes32 dataHash, uint256 timestamp);

    function storeHash(uint256 batchId, bytes32 dataHash) public {
        anchors[batchId] = Anchor(dataHash, block.timestamp);
        batchCount++;
        emit Anchored(batchId, dataHash, block.timestamp);
    }

    function getHash(uint256 batchId) public view returns (bytes32) {
        return anchors[batchId].dataHash;
    }
}
