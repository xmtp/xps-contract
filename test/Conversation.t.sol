// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { Test } from "forge-std/Test.sol";
import { VmSafe } from "forge-std/Vm.sol";

import { Test } from "forge-std/Test.sol";

import { Conversation } from "../contracts/Conversation.sol";
import { createMessageSender } from "../contracts/MessageSenderProxy.sol";
import { MessageSender } from "../contracts/MessageSender.sol";

contract ConversationTest is Test {
    event PayloadSent(bytes32 indexed conversation, bytes payload);

    address internal constant ROLE_ADMIN = address(0x45ee);

    MessageSender public conversation;

    function setUp() public {
        address _senderAddress = createMessageSender(ROLE_ADMIN);
        conversation = MessageSender(_senderAddress);
    }

    function testSendMessage() public {
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        vm.expectEmit(true, true, false, true);
        emit PayloadSent(cid, expectMsg);
        conversation.sendMessage(cid, expectMsg);
    }

    function testSupportsInterfaceIERC165() public {
        IERC165 _conversation = IERC165(address(conversation));
        bool result = _conversation.supportsInterface(type(IERC165).interfaceId);
        assertTrue(result, "should support IERC165");
    }

    function testSupportsInterfaceIAccessControl() public {
        IERC165 _conversation = IERC165(address(conversation));
        bool result = _conversation.supportsInterface(type(IAccessControl).interfaceId);
        assertTrue(result, "should support IAccessControl");
    }

    function testSupportsInterfaceMessageSender() public {
        IERC165 _conversation = IERC165(address(conversation));
        bool result = _conversation.supportsInterface(type(MessageSender).interfaceId);
        assertTrue(result, "should support EIP1056conversation.");
    }

    function testDefaultRoleIsSet() public {
        Conversation _conversation = Conversation(address(conversation));
        assertTrue(_conversation.hasRole(_conversation.DEFAULT_ADMIN_ROLE(), ROLE_ADMIN));
    }

    function testGrantRole() public {
        Conversation _conversation = Conversation(address(conversation));
        address _next = address(0x123);
        assertEq(
            _conversation.DEFAULT_ADMIN_ROLE(),
            _conversation.getRoleAdmin(_conversation.INBOX_ADMIN_ROLE()),
            "expect default admin role"
        );
        vm.startPrank(ROLE_ADMIN);
        _conversation.grantRole(_conversation.INBOX_ADMIN_ROLE(), _next);
        vm.stopPrank();
        assertFalse(_conversation.hasRole(_conversation.DEFAULT_ADMIN_ROLE(), _next));
        assertTrue(_conversation.hasRole(_conversation.INBOX_ADMIN_ROLE(), _next));
    }

    function testRevokeOwner() public {
        Conversation _conversation = Conversation(address(conversation));
        vm.startPrank(ROLE_ADMIN);
        _conversation.revokeRole(_conversation.DEFAULT_ADMIN_ROLE(), address(this));
        vm.stopPrank();
        assertFalse(_conversation.hasRole(_conversation.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    function testUpgradeAsAdmin() public {
        Conversation _conversation = Conversation(address(conversation));
        Conversation logic = new Conversation();
        address upgradeAdmin = address(0x123);
        vm.startPrank(ROLE_ADMIN);
        _conversation.grantRole(_conversation.INBOX_ADMIN_ROLE(), upgradeAdmin);
        vm.stopPrank();
        vm.prank(upgradeAdmin);
        vm.expectEmit();
        emit ERC1967Utils.Upgraded(address(logic));
        _conversation.upgradeToAndCall(address(logic), "");
    }

    function testUpgradeNotPermitted() public {
        Conversation _conversation = Conversation(address(conversation));
        Conversation logic = new Conversation();
        address badActor = address(0xffff);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                badActor,
                _conversation.INBOX_ADMIN_ROLE()
            )
        );
        vm.prank(badActor);
        _conversation.upgradeToAndCall(address(logic), "");
    }

    function testRevokeDefaultAdminRole() public {
        Conversation _conversation = Conversation(address(conversation));
        address upgradeAdmin = address(0x133);
        vm.startPrank(ROLE_ADMIN);
        _conversation.grantRole(_conversation.INBOX_ADMIN_ROLE(), upgradeAdmin);
        vm.stopPrank();
        Conversation logic = new Conversation();
        vm.expectEmit();
        emit ERC1967Utils.Upgraded(address(logic));
        vm.prank(upgradeAdmin);
        _conversation.upgradeToAndCall(address(logic), "");
        vm.startPrank(ROLE_ADMIN);
        _conversation.revokeRole(_conversation.INBOX_ADMIN_ROLE(), upgradeAdmin);
        _conversation.revokeRole(_conversation.DEFAULT_ADMIN_ROLE(), ROLE_ADMIN);
        vm.stopPrank();
        assertFalse(_conversation.hasRole(_conversation.INBOX_ADMIN_ROLE(), upgradeAdmin));
        assertFalse(_conversation.hasRole(_conversation.DEFAULT_ADMIN_ROLE(), ROLE_ADMIN));
    }

    function testDuplicateInitializeFails() public {
        Conversation _conversation = Conversation(address(conversation));
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        _conversation.initialize(address(0x123));
    }

    function testInitializeNotPossible() public {
        Conversation _conversation = new Conversation();
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        _conversation.initialize(address(0x123));
    }
}
