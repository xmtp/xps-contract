// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Inbox {
    event MessageSent(address indexed recipient, string cid);

    function sendMessage(address recipient, string memory cid) public payable {
        emit MessageSent(recipient, cid);
    }
}
