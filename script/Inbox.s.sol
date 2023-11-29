// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract InboxScript is Script {
    function run() public {
        vm.broadcast();
    }
}
