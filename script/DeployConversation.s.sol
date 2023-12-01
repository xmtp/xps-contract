// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { MessageSenderProxy } from "../contracts/MessageSenderProxy.sol";
import { MessageSender } from "../contracts/MessageSender.sol";
import { Conversation } from "../contracts/Conversation.sol";

contract DeployConversation is Script {
    event ConversationDeployed(address proxy);

    /**
     * @notice - deploy Conversation Proxy
     */
    function deploy() public {
        vm.startBroadcast();
        address _contractRoleAdmin = vm.envAddress("CONTRACT_ROLE_ADMIN");
        address[] memory _contractUpgradeAdmin = vm.envAddress("CONTRACT_ROLE_UPGRADE", ",");
        Conversation logic = new Conversation();
        MessageSenderProxy proxy = new MessageSenderProxy(address(logic), _contractRoleAdmin);
        address proxyAddress = address(proxy);
        Conversation conversation = Conversation(proxyAddress);
        for (uint256 i = 0; i < _contractUpgradeAdmin.length; i++) {
            address admin = _contractUpgradeAdmin[i];
            conversation.grantRole(logic.INBOX_ADMIN_ROLE(), admin);
        }
        emit ConversationDeployed(proxyAddress);
        vm.stopBroadcast();
    }

    /**
     * @notice - upgrade Conversation Proxy
     */
    function upgrade() external {
        vm.startBroadcast();
        address _proxyAddress = vm.envAddress("PROXY_ADDRESS");
        Conversation logic = new Conversation();
        Conversation proxy = Conversation(_proxyAddress);
        proxy.upgradeToAndCall(address(logic), "");
        vm.stopBroadcast();
    }
}
