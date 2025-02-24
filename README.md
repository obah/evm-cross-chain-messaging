# CrossChainMessenger

## Overview

The `CrossChainMessenger` contract enables cross-chain communication by allowing users to send messages from one blockchain to another. It supports multiple chains, ensures messages are uniquely identified, and prevents duplicate processing. Built with security in mind, it inherits from OpenZeppelin's `Pausable` and `ReentrancyGuard` contracts to allow pausing in emergencies and protect against reentrancy attacks.

## Features

- **Send Messages**: Users can send messages to a recipient on a different chain.
- **Receive Messages**: Messages can be received and processed on the destination chain by calling a target contract.
- **Chain Support Management**: The contract owner can enable or disable support for specific chains.
- **Pausable**: The owner can pause the contract to halt message reception during emergencies.
- **Reentrancy Protection**: Prevents reentrancy attacks using OpenZeppelin's `ReentrancyGuard`.
- **Event Tracking**: Emits events for message sending, receiving, and chain status updates.

## Usage

### Deployment

1. Deploy the `CrossChainMessenger` contract on each chain where cross-chain messaging is desired.
2. The deployer is set as the `OWNER` and gains administrative privileges to manage supported chains and pausing functionality.

### Setting Supported Chains

The owner must configure the chains supported for messaging:

```solidity
function setSupportedChain(uint32 chainId, bool supported) external onlyOwner;
```

- Call `setSupportedChain(chainId, true)` to enable messaging to/from a specific chain.
- Use `setSupportedChain(chainId, false)` to disable a chain if needed.

### Sending a Message

Users send messages to another chain using:

```solidity
function sendMessage(
    address _userAddress,
    uint32 _toChainId,
    bytes memory _message,
    address _toAddress
) external payable returns (bytes32);
```

- `_userAddress`: The sender's address (can be specified by the caller).
- `_toChainId`: The destination chain ID.
- `_message`: The message data (e.g., an encoded function call).
- `_toAddress`: The recipient's address on the destination chain.

**Example**:
To call `setValue(uint256)` with `42` on a contract at `targetAddress` on chain `2`:

```solidity
bytes memory messageData = abi.encodeWithSignature("setValue(uint256)", 42);
bytes32 messageHash = crossChainMessenger.sendMessage(userAddress, 2, messageData, targetAddress);
```

The function returns a `messageHash` for tracking and emits a `MessageSent` event.

### Receiving a Message

Messages are processed on the destination chain via:

```solidity
function receiveMessage(
    address _userAddress,
    bytes calldata _message,
    address _targetAddress,
    uint256 _messageId,
    uint32 _fromChainId,
    bytes32 _messageHash
) external payable nonReentrant whenNotPaused returns (bytes memory);
```

- Typically called by a bridge or operator after the message is transferred across chains.
- Executes the message by calling `_targetAddress` with `_message` and any attached ETH (`msg.value`).
- Emits a `MessageReceived` event upon success.

### Utility Functions

- **getFunctionBytes**: Helps encode function calls for message data.

```solidity
function getFunctionBytes(string memory _functionSig, uint256 _param) external pure returns (bytes memory);
```

**Example**:
```solidity
bytes memory messageData = crossChainMessenger.getFunctionBytes("setValue(uint256)", 42);
```

## Events

- **MessageSent**:
  ```solidity
  event MessageSent(address to, uint32 toChainId, bytes messageData, address indexed sender, uint256 indexed messageId, bytes32 indexed messageHash);
  ```
  Emitted when a message is sent.

- **ChainStatusUpdated**:
  ```solidity
  event ChainStatusUpdated(uint32 chainId, bool supported);
  ```
  Emitted when a chain's support status changes.

- **MessageReceived**:
  ```solidity
  event MessageReceived(address indexed from, uint32 fromChainId, bytes message, uint256 indexed messageId);
  ```
  Emitted when a message is processed.

## Security Considerations

- **Missing Verification**: The `receiveMessage` function lacks message verification (noted by a commented-out `_verifyMessage`). Without it, anyone can send or process messages on behalf of any address, posing a significant security risk. Implement cryptographic signatures or bridge-specific proofs before production use.
- **Bridging Not Implemented**: The contract assumes a bridging mechanism (e.g., "across") will transfer messages between chains, but this is not included. A secure, external bridge is required.
- **Sender Delegation**: `sendMessage` uses `_userAddress` instead of `msg.sender`, allowing delegation. Without authentication, this could enable spoofing; consider restricting or verifying callers.
- **ETH Handling**: `receiveMessage` forwards `msg.value` to the target contract. Ensure the target is trusted to handle ETH securely.
- **Pausable**: Only the owner can pause/unpause, useful for emergencies but centralizes control.

## Dependencies

- **OpenZeppelin Contracts**:
  - `@openzeppelin/contracts/utils/ReentrancyGuard.sol`
  - `@openzeppelin/contracts/utils/Pausable.sol`
- **Solidity Version**: `^0.8.26`

Install via npm:
```bash
npm install @openzeppelin/contracts
```

## License

Licensed under the [MIT License](https://opensource.org/licenses/MIT), as specified by `SPDX-License-Identifier: MIT`.

## Notes

This contract is a work in progress. Key features like message verification and bridging are incomplete. Use caution and enhance security before deploying to a live environment. Future improvements could include robust verification, decentralized access control, and gas optimizations.
