// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/Inbox.sol";

contract InboxTest is Test {
    Inbox public inbox;
    event MessageSent(address indexed recipient, string cid);

    function setUp() public {
        inbox = new Inbox();
    }

    function testSendMessage() public {
        vm.expectEmit(true, true, false, true);
        emit MessageSent(address(0), "hi");
        inbox.sendMessage(address(0), "hi");
    }
}
