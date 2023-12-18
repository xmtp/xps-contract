// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { MessageSender } from "./MessageSender.sol";

/**
 * @notice Conversation is a contract for sending messages to an inbox.   Each inbox
 * is identified by a conversationId.  The conversationId is a hash of the internal id
 * known to participants in a group chat.  The internal id is not known or shared in this
 * contract.
 */
contract Conversation is MessageSender, Initializable, UUPSUpgradeable, AccessControl {
    bytes32 public constant INBOX_ADMIN_ROLE = keccak256("INBOX_ADMIN_ROLE");

    mapping(bytes32 => uint256) public lastMessage;

    /// @dev constructor is forbidden for upgradeable contracts
    constructor() {
        _disableInitializers();
    }

    /// @dev initializer is required for proxy contracts
    function initialize(address _roleAdmin) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
    }

    /**
     * @notice send a message to the inbox
     * @param conversationId the conversation id
     * @param payload the message payload
     */
    function sendMessage(bytes32 conversationId, bytes memory payload) external {
        uint latest = lastMessage[conversationId];
        emit PayloadSent(conversationId, payload, latest);
        lastMessage[conversationId] = block.number;
    }

    /**
     * @notice authorize code upgrade or revert
     * @dev required by UUPSUpgradeable
     */
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address
    )
        internal
        override
        onlyRole(INBOX_ADMIN_ROLE) // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @dev required by ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return
            interfaceId == type(MessageSender).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
