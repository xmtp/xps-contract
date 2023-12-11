// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface MessageSender {
    /**
     * @notice emitted when a message is sent
     * @param conversationId the conversation id
     * @param payload the message payload
     * @param lastMessage the latest change block number of this inbox for the conversation
     */
    event PayloadSent(bytes32 indexed conversationId, bytes payload, uint256 lastMessage);

    /**
     * @notice send a message to the inbox
     * @param conversationId the conversation id
     * @param payload the message payload
     */
    function sendMessage(bytes32 conversationId, bytes memory payload) external;

    /**
     * @notice get the latest message block number of this inbox for the conversation
     * @param conversationId the conversation id
     * @return the latest change block number of this inbox for the conversation
     */
    function lastMessage(bytes32 conversationId) external view returns (uint256);
}
