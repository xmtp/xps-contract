// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Inbox {
    event MessageSent(bytes32 recipient, string message);

    function send(bytes32 recipient, string memory message) public payable {
        emit MessageSent(recipient, message);
    }
}
