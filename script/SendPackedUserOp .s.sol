// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MinimalAccount} from "../src/ MinimalAccount.sol";
///////////////////////////////// @title SendPackedUserOp.sol

/// @notice account sign this contracts, which is a owner of
contract SendPackedUserOp is Script {
    PackedUserOperation public userOp;

    function run() external {}

    function generateSignedUserOperation(
        address sender,
        bytes memory callData,
        HelperConfig.NetworkConfig memory config
    ) public returns (PackedUserOperation memory) {
        //1.get the struct of PackedUserOperation
        uint256 nonce = vm.getNonce(sender) - 1;//硬性规定，不-1会报错
        userOp = _generateSignedUserOperation(sender, callData, nonce);
        //give the signature of the userOp

        //get the private key of the sender
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            userOp
        );
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        // 3. Sign it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v); // Note the order
        return userOp;
    }

    function _generateSignedUserOperation(
        address sender,
        bytes memory callData,
        uint256 nonce
    ) internal pure returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        //2. get the struct of PackedUserOperation
        PackedUserOperation memory Operation = PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(
                (uint256(verificationGasLimit) << 128) | callGasLimit
            ),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(
                (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
            ),
            paymasterAndData: hex"",
            signature: hex""
        });
        return Operation;
    }
}
