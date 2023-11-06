// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Inbox {
    event MessageSent(address indexed recipient, string cid);

    function sendMessage(address recipient, string memory cid) public payable {
        emit MessageSent(recipient, cid);
    }
}
