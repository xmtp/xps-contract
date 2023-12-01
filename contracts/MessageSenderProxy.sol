// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import { MessageSender } from "./MessageSender.sol";
import { Conversation } from "./Conversation.sol";

contract MessageSenderProxy is ERC1967Proxy {
    constructor(
        address _logic,
        address _roleAdmin
    )
        ERC1967Proxy(_logic, abi.encodeWithSignature("initialize(address)", _roleAdmin))
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

// solhint-disable-next-line func-visibility
function createMessageSender(address _roleAdmin) returns (address) {
    Conversation logic = new Conversation(); // logic contract
    MessageSenderProxy proxy = new MessageSenderProxy(address(logic), _roleAdmin);
    return address(proxy);
}
