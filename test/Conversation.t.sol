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

/**
 * @dev Convert bytes to uint256.  This is intended for test purposes only.
 * @param _bytes Bytes to convert
 * @return uint256
 */
function toUint256(bytes memory _bytes) pure returns (uint256) {
    require(_bytes.length <= 32, "toUint256_outOfBounds");
    uint256 result;
    // solhint-disable-next-line no-inline-assembly
    assembly {
        result := mload(add(_bytes, 0x20))
    }
    return result;
}

contract ConversationTest is Test {
    address internal constant ROLE_ADMIN = address(0x45ee);

    bytes internal constant PRIVATE_KEY = hex"a285ab66393c5fdda46d6fbad9e27fafd438254ab72ad5acb681a0e9f20f5d7b";
    address internal constant SIGNER = 0x2036C6CD85692F0Fb2C26E6c6B2ECed9e4478Dfd;

    event PayloadSent(bytes32 indexed conversationId, bytes payload, uint256 lastMessage);

    MessageSender public conversation;

    function setUp() public {
        address _senderAddress = createMessageSender(ROLE_ADMIN);
        conversation = MessageSender(_senderAddress);
    }

    function testSendMessage() public {
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        vm.expectEmit();
        emit PayloadSent(cid, expectMsg, 0);
        conversation.sendMessage(cid, expectMsg);
    }

    function testSendMessageLastMessageExpected() public {
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        uint expectBlock = block.number;
        assertTrue(expectBlock > 0);
        vm.expectEmit();
        emit PayloadSent(cid, expectMsg, 0);
        conversation.sendMessage(cid, expectMsg);
        vm.expectEmit();
        emit PayloadSent(cid, expectMsg, expectBlock);
        conversation.sendMessage(cid, expectMsg);
    }

    function testSendMessageSigned() public {
        Conversation _conversation = Conversation(address(conversation));
        uint256 _nonce = _conversation.nonce(SIGNER);
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        (uint8 v, bytes32 r, bytes32 s) = signData(vm, cid, expectMsg, SIGNER, PRIVATE_KEY, _nonce);
        vm.expectEmit();
        emit PayloadSent(cid, expectMsg, 0);
        conversation.sendMessageSigned(cid, expectMsg, SIGNER, v, r, s);
    }

    function testSendMessageSignedNonceUpdate() public {
        Conversation _conversation = Conversation(address(conversation));
        uint256 _startNonce = _conversation.nonce(SIGNER);
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        (uint8 v, bytes32 r, bytes32 s) = signData(vm, cid, expectMsg, SIGNER, PRIVATE_KEY, _startNonce);
        vm.expectEmit();
        emit PayloadSent(cid, expectMsg, 0);
        conversation.sendMessageSigned(cid, expectMsg, SIGNER, v, r, s);
        uint256 _nonce = _conversation.nonce(SIGNER);
        (v, r, s) = signData(vm, cid, expectMsg, SIGNER, PRIVATE_KEY, _nonce);
        vm.expectEmit();
        emit PayloadSent(cid, expectMsg, block.number);
        conversation.sendMessageSigned(cid, expectMsg, SIGNER, v, r, s);
        assertNotEq(_nonce, _startNonce);
    }

    function testSendMessageSignedValidationFailure() public {
        Conversation _conversation = Conversation(address(conversation));
        uint256 _nonce = _conversation.nonce(SIGNER);
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        (uint8 v, bytes32 r, bytes32 s) = signData(vm, cid, expectMsg, SIGNER, PRIVATE_KEY, _nonce);
        address badActor = address(0x123);
        vm.expectRevert(abi.encodeWithSelector(MessageSender.SignatureValidationFailed.selector, badActor));
        conversation.sendMessageSigned(cid, expectMsg, badActor, v, r, s);
    }

    function testSendMessageSignedNonceFailureReplay() public {
        Conversation _conversation = Conversation(address(conversation));
        uint256 _nonce = _conversation.nonce(SIGNER);
        bytes32 cid = keccak256("conversation");
        bytes memory expectMsg = "hello";
        (uint8 v, bytes32 r, bytes32 s) = signData(vm, cid, expectMsg, SIGNER, PRIVATE_KEY, _nonce);
        conversation.sendMessageSigned(cid, expectMsg, SIGNER, v, r, s);
        vm.expectRevert(abi.encodeWithSelector(MessageSender.SignatureValidationFailed.selector, SIGNER));
        conversation.sendMessageSigned(cid, expectMsg, SIGNER, v, r, s);
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

    function signData(
        VmSafe _vm,
        bytes32 _cid,
        bytes memory _payload,
        address _identity,
        bytes memory _privateKey,
        uint256 _ownerNonce
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 digest = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), _cid, _payload, _identity, _ownerNonce));
        (v, r, s) = _vm.sign(toUint256(_privateKey), digest);
        return (v, r, s);
    }
}
