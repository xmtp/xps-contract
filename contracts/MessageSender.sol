// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface MessageSender {
    /**
     * @notice emitted when a message is sent
     * @param conversationId the conversation id
     * @param payload the message payload
     * @param lastChange the latest change block number of this inbox for the conversation
     */
    event PayloadSent(bytes32 indexed conversationId, bytes payload, uint256 lastChange);

    /**
     * @notice send a message to the inbox
     * @param conversationId the conversation id
     * @param payload the message payload
     */
    function sendMessage(bytes32 conversationId, bytes memory payload) external;
}
