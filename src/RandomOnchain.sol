// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

contract RandomOnchain {
    function getRandomOnchain() public view returns (uint256) {
        bytes32 randomBytes = keccak256(abi.encodePacked(block.timestamp, msg.sender, blockhash(block.number - 1)));

        return uint256(randomBytes);
    }
}
