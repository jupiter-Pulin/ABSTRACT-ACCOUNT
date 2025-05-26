// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ZKMinimalAccount} from "src/ZKMinmalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Transaction, MemoryTransactionHelper} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";

contract ZKMinimalAccountTest is Test {
    using MemoryTransactionHelper for Transaction;
    ZKMinimalAccount public zkMinimalAccount;

    ERC20Mock public usdc;

    uint256 constant AMOUNT = 1e18;
    bytes32 constant EMPTY_BYTES32 = bytes32(0);
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public randomuser = makeAddr("randomuser");

    function setUp() public {
        usdc = new ERC20Mock();

        // Use the account from config,uint test is avail account

        zkMinimalAccount = new ZKMinimalAccount();
        zkMinimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
    }

    function testOwnerCanExcute() public {
        //ARRANGE
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeCall(
            usdc.mint,
            (address(zkMinimalAccount), AMOUNT)
        );
        //ACT
        //vm.prank(helperConfig.getConfig().account); they both the same thing!!!
        vm.prank(zkMinimalAccount.owner());
        Transaction memory transaction = _createSignature(
            113,
            address(zkMinimalAccount),
            dest,
            value,
            functionData
        );
        zkMinimalAccount.executeTransaction(
            EMPTY_BYTES32,
            EMPTY_BYTES32,
            transaction
        );
        // ASSERT
        assertEq(usdc.balanceOf(address(zkMinimalAccount)), AMOUNT);
    }

    function testNotOwnerCannotExcute() public {
        //ARRANGE
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeCall(
            usdc.mint,
            (address(zkMinimalAccount), AMOUNT)
        );
        //ACT
        //vm.prank(helperConfig.getConfig().account); they both the same thing!!!
        vm.prank(randomuser);
        Transaction memory transaction = _createSignature(
            113,
            address(zkMinimalAccount),
            dest,
            value,
            functionData
        );
        //ASSERT
        vm.expectRevert(
            ZKMinimalAccount.ZkMinimalAccount__NotFromBootLoaderOrOwner.selector
        );
        zkMinimalAccount.executeTransaction(
            EMPTY_BYTES32,
            EMPTY_BYTES32,
            transaction
        );
    }

    // need --system-mode=true to run this test
    function testZkValidateTransaction() public {
        //ARRANGE
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeCall(
            usdc.mint,
            (address(zkMinimalAccount), AMOUNT)
        );
        //ACT
        Transaction memory transaction = _createSignature(
            113,
            address(zkMinimalAccount),
            dest,
            value,
            functionData
        );
        bytes4 magic = zkMinimalAccount.validateTransaction(
            EMPTY_BYTES32,
            EMPTY_BYTES32,
            transaction
        );
        //ASSERT
        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    /////////////////////////////////////////////////////////////////
    //                    HELPER FUNCTIONS
    /////////////////////////////////////////////////////////////////
    function _createSignature(
        uint8 transactionType,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal view returns (Transaction memory) {
        // Create a transaction with the owner as the sender
        Transaction memory transaction = _createTransaction(
            transactionType,
            from,
            to,
            value,
            data
        );
        bytes32 txHash = transaction.encodeHash();
        // Sign the transaction hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            zkMinimalAccount.owner(),
            txHash
        );
        // Set the signature in the transaction
        transaction.signature = abi.encodePacked(r, s, v);
        return transaction;
    }

    function _createTransaction(
        uint8 transactionType,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal view returns (Transaction memory) {
        uint256 nonce = vm.getNonce(address(zkMinimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);
        return
            Transaction({
                txType: transactionType,
                from: uint256(uint160(from)),
                // The callee.
                to: uint256(uint160(to)),
                gasLimit: 16777216, //16M gas 在测试环境中通常足够大，确保交易不会因为 gas 不足而失败,
                gasPerPubdataByteLimit: 16777216,
                maxFeePerGas: 16777216,
                maxPriorityFeePerGas: 16777216,
                paymaster: 0,
                nonce: nonce,
                value: value,
                reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
                data: data,
                signature: hex"", // The signature will be filled in later
                factoryDeps: factoryDeps,
                paymasterInput: hex"",
                reservedDynamic: hex""
            });
    }
}
