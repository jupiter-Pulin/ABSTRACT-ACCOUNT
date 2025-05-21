// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {MinimalAccount} from "../src/ MinimalAccount.sol";

contract DeployMinimal is Script {
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;

    EntryPoint public entryPoint;

    function run() external {
        deployMinimal();
    }

    function deployMinimal() public returns (HelperConfig, MinimalAccount) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast(config.account);
        minimalAccount = new MinimalAccount(config.entryPoint);
        vm.stopBroadcast();
        return (helperConfig, minimalAccount);
    }
}
