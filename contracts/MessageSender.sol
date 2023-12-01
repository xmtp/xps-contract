// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface MessageSender {
    event PayloadSent(bytes32 indexed conversationId, bytes payload);

    /**
     * @notice send a message to the inbox
     * @param conversationId the conversation id
     * @param payload the message payload
     */
    function sendMessage(bytes32 conversationId, bytes memory payload) external;
}
