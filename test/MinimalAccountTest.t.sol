// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../src/ MinimalAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployMinimal} from "script/DeployMinimal.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp} from "script/SendPackedUserOp .s.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccountTest is Test {
    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;
    DeployMinimal public deployMinimal;
    ERC20Mock public usdc;
    SendPackedUserOp public sendPackedUserOp;
    address public randomuser = makeAddr("randomuser");

    uint256 constant AMOUNT = 1000 * 1e6; // 1000 USDC

    function setUp() public {
        deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimal();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    //execute(address dest, uint256 value, bytes calldata functionData)
    function testOwnerCanExecuteCommands() public {
        //ARRANGE
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeCall(
            usdc.mint,
            (address(minimalAccount), AMOUNT)
        );
        //ACT
        //vm.prank(helperConfig.getConfig().account); they both the same thing!!!
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        // ASSERT
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNotOwnerCannotExecuteCommands() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeCall(
            usdc.mint,
            (address(minimalAccount), AMOUNT)
        );
        vm.expectRevert(
            MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector
        );
        minimalAccount.execute(dest, value, functionData);
    }

    // function testRecoverSignedOp() public {
    //     //ARRANGE
    //     address dest = address(usdc);
    //     uint256 value = 0;
    //     bytes memory functionData = abi.encodeCall(
    //         usdc.mint,
    //         (address(minimalAccount), AMOUNT)
    //     );
    //     bytes memory excuteData = abi.encodeCall(
    //         minimalAccount.execute,
    //         (dest, value, functionData)
    //     );
    //     PackedUserOperation memory userOp = sendPackedUserOp
    //         .generateSignedUserOperation(
    //             address(minimalAccount),
    //             excuteData,
    //             helperConfig.getConfig()
    //         );
    //     bytes32 opHash = IEntryPoint(helperConfig.getConfig().entryPoint)
    //         .getUserOpHash(userOp);
    //     //ACT
    //     MessageHashUtils.toEthSignedMessageHash(opHash);
    //     address signer = ECDSA.recover(
    //         MessageHashUtils.toEthSignedMessageHash(opHash),
    //         userOp.signature
    //     );
    //     //ASSERT
    //     assertEq(signer, minimalAccount.owner());
    // }
    // 1. Sign user ops
    // 2. Call validate userops
    // 3. Assert the return is correct
    function testValidateUserOp() public {
        //ARRANGE
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeCall(
            usdc.mint,
            (address(minimalAccount), AMOUNT)
        );
        bytes memory excuteData = abi.encodeCall(
            minimalAccount.execute,
            (dest, value, functionData)
        );
        PackedUserOperation memory userOp = sendPackedUserOp
            .generateSignedUserOperation(
                address(minimalAccount),
                excuteData,
                helperConfig.getConfig()
            );
        bytes32 opHash = IEntryPoint(helperConfig.getConfig().entryPoint)
            .getUserOpHash(userOp);
        //ACT
        vm.prank(minimalAccount.getEntryPoint());
        uint256 validationData = minimalAccount.validateUserOp(
            userOp,
            opHash,
            0
        );
        //ASSERT
        assertEq(validationData, 1);
    }
}
