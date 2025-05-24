# MinimalAccount: A Simple Account Abstraction Implementation

This project provides a minimal implementation of an [ERC-4337]-style smart contract wallet using Account Abstraction. The contract supports signed user operations and allows execution of arbitrary calls through an `EntryPoint` contract.

---

## 🧱 Components Overview

### 1. `MinimalAccount.sol`
- A minimal smart contract wallet that:
  - Is owned by a single externally owned account (EOA).
  - Validates `PackedUserOperation` based on ECDSA signatures.
  - Supports the `execute` function to call any contract or transfer ETH.
  - Can only be interacted with via its owner or the configured `EntryPoint`.

### 2. `SendPackedUserOp.s.sol`
- Script to:
  - Construct and sign `PackedUserOperation` data.
  - Simulate entry point signature creation using a local private key (e.g., Anvil default key).

### 3. `MinimalAccountTest.t.sol`
- Tests for:
  - Execution permissions (only owner can execute).
  - UserOp signature recovery and validation via `validateUserOp`.

---

## 📁 Project Structure

```
├── src/
│   └── MinimalAccount.sol          # Main smart contract
├── script/
│   ├── HelperConfig.s.sol          # Helper network configuration
│   ├── DeployMinimal.s.sol         # Deployment script (not shown here)
│   └── SendPackedUserOp.s.sol      # UserOperation generator
├── test/
│   └── MinimalAccountTest.t.sol    # Foundry test suite
```

---

## 🚀 Getting Started

### Requirements
- [Foundry](https://book.getfoundry.sh/) (`forge`, `cast`)
- Node.js & npm (optional, for frontend or additional scripting)
- A local or testnet Ethereum environment (Anvil recommended)

### Install Dependencies

```bash
forge install
```

### Compile

```bash
forge build
```

### Run Tests

```bash
forge test -vvv
```

---

## 🔐 Key Features

- **Signature Validation:** Verifies `PackedUserOperation` with ECDSA signatures using `MessageHashUtils`.
- **EntryPoint Restriction:** Restricts sensitive functions like `validateUserOp` and `execute` to be callable only by the owner or the `EntryPoint` contract.
- **Unit Testing:** Includes a suite of tests to validate permissions, signature recovery, and userOp behavior.

---

## 🧪 Test Coverage

### ✅ `testOwnerCanExecuteCommands`
Ensures the owner can mint tokens via `execute`.

### ❌ `testNotOwnerCannotExecuteCommands`
Ensures unauthorized users can't use `execute`.

### ✅ `testValidateUserOp`
Validates that signed `PackedUserOperation` is accepted by the contract when correctly signed.

---

## ✍️ Example Usage

### Signing a UserOperation

```solidity
PackedUserOperation memory userOp = sendPackedUserOp
    .generateSignedUserOperation(
        address(minimalAccount),
        abi.encodeCall(
            minimalAccount.execute,
            (dest, value, functionData)
        ),
        helperConfig.getConfig()
    );
```

---

## 🛠️ Customization Tips

- Replace `ANVIL_DEFAULT_KEY` with a different private key when deploying to a non-local network.
- Extend `MinimalAccount` with modules for batching, paymaster integration, etc.
- Implement `validateNonce` for enhanced security and replay protection.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙌 Acknowledgments

- [Account Abstraction (ERC-4337)](https://eips.ethereum.org/EIPS/eip-4337)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Foundry](https://book.getfoundry.sh/) for powerful testing and scripting
