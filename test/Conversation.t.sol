// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Conversation } from "../contracts/Conversation.sol";

contract InboxTest is Test {
    Conversation public conversation;
    event PayloadSent(bytes32 indexed conversation, bytes payload);

    function setUp() public {
        conversation = new Conversation();
    }

    function testSendMessage() public {
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        vm.expectEmit(true, true, false, true);
        emit PayloadSent(cid, expectMsg);
        conversation.sendMessage(cid, expectMsg);
    }
}
