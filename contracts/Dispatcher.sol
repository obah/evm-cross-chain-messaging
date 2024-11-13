//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Dispatcher is Ownable, Pausable, ReentrancyGuard {
    error UnsupportedChain();
    error InvalidAddress();

    event MessageSent(
        address to,
        uint32 toChainId,
        bytes messageData,
        address indexed sender,
        uint256 indexed messageId,
        bytes32 indexed messageHash
    );

    event ChainStatusUpdated(uint32 chainId, bool supported);

    // event Dispatched(
    //     uint32 destinationChain,
    //     address sender,
    //     bytes message,
    //     bytes32 indexed messageBytes,
    //     uint256 indexed messageId
    // );

    constructor() Ownable(msg.sender) {}

    uint256 public nonce;

    mapping(bytes32 => bool) public sentMessages;
    mapping(uint32 => bool) public supportedChains;

    //todo implement bridge later using across
    // function bridge() external {};

    function setSupportedChain(
        uint32 chainId,
        bool supported
    ) external onlyOwner {
        supportedChains[chainId] = supported;
        emit ChainStatusUpdated(chainId, supported);
    }

    function pause() internal onlyOwner {
        _pause();
    }

    function unpause() internal onlyOwner {
        _unpause();
    }

    function sendMessage(
        address _userAddress,
        uint32 _chainId,
        bytes memory _message,
        address _target
    ) external payable returns (bytes32) {
        if (!supportedChains[_chainId]) revert UnsupportedChain();
        if (_target == address(0)) revert InvalidAddress();

        nonce += 1;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                block.chainid,
                _chainId,
                msg.sender,
                _target,
                nonce,
                _message
            )
        );

        sentMessages[messageHash] = true;

        emit MessageSent(
            _target,
            _chainId,
            _message,
            _userAddress,
            nonce,
            messageHash
        );

        return messageHash;
    }
}

interface IAave {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

// contract AaveTest {
//     address userAddr = msg.sender;
//     uint32 chainId = 11155111;
//     address target = address(0); //Aave pool address

//     function supplyToken() external {
//         bytes memory message = abi.encodeWithSignature(
//             "function supply(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;",
//             address(0),
//             100,
//             msg.sender,
//             0
//         );

//         Dispatcher.Dispatcher(address(this)).dispatch(
//             userAddr,
//             chainId,
//             message,
//             target
//         );
//     }
// }

// Contract for sending messages (on source chain)
// contract MessageDispatcher is Ownable, Pausable, ReentrancyGuard {
//     IMessageRelay public relay;

//     // Message tracking
//     mapping(bytes32 => bool) public sentMessages;
//     uint256 public nonce;

//     // Chain configuration
//     mapping(uint32 => bool) public supportedChains;

//     // Events
//     event MessageDispatched(
//         bytes32 indexed messageId,
//         uint32 destinationChainId,
//         address recipient,
//         bytes message,
//         uint256 nonce
//     );
//     event RelayUpdated(address newRelay);
//     event ChainStatusUpdated(uint32 chainId, bool supported);

//     constructor(address _relay) {
//         relay = IMessageRelay(_relay);
//     }

//     // Admin functions
//     function setRelay(address _relay) external onlyOwner {
//         require(_relay != address(0), "Invalid relay address");
//         relay = IMessageRelay(_relay);
//         emit RelayUpdated(_relay);
//     }

//     function setSupportedChain(
//         uint32 chainId,
//         bool supported
//     ) external onlyOwner {
//         supportedChains[chainId] = supported;
//         emit ChainStatusUpdated(chainId, supported);
//     }

//     function pause() external onlyOwner {
//         _pause();
//     }

//     function unpause() external onlyOwner {
//         _unpause();
//     }

//     // Main dispatch function
//     function dispatch(
//         uint32 destinationChainId,
//         address recipient,
//         bytes calldata message
//     ) external nonReentrant whenNotPaused returns (bytes32) {
//         require(supportedChains[destinationChainId], "Unsupported chain");
//         require(recipient != address(0), "Invalid recipient");

//         // Create message ID using current nonce
//         bytes32 messageId = keccak256(
//             abi.encodePacked(
//                 block.chainid,
//                 destinationChainId,
//                 msg.sender,
//                 recipient,
//                 nonce,
//                 message
//             )
//         );

//         // Send message through relay
//         relay.sendMessage(destinationChainId, recipient, message);

//         // Track message
//         sentMessages[messageId] = true;
//         nonce++;

//         emit MessageDispatched(
//             messageId,
//             destinationChainId,
//             recipient,
//             message,
//             nonce - 1
//         );

//         return messageId;
//     }
// }

// // Contract for receiving messages (on destination chain)
// contract MessageHandler is Ownable, Pausable, ReentrancyGuard {
//     IMessageRelay public relay;

//     // Message tracking
//     mapping(bytes32 => bool) public processedMessages;

//     // Chain configuration
//     mapping(uint32 => bool) public trustedSources;
//     mapping(address => bool) public trustedSenders;

//     // Events
//     event MessageProcessed(
//         bytes32 indexed messageId,
//         uint32 sourceChainId,
//         address sender,
//         bytes message
//     );
//     event TrustedSourceUpdated(uint32 chainId, bool trusted);
//     event TrustedSenderUpdated(address sender, bool trusted);

//     constructor(address _relay) {
//         relay = IMessageRelay(_relay);
//     }

//     // Admin functions
//     function setTrustedSource(uint32 chainId, bool trusted) external onlyOwner {
//         trustedSources[chainId] = trusted;
//         emit TrustedSourceUpdated(chainId, trusted);
//     }

//     function setTrustedSender(address sender, bool trusted) external onlyOwner {
//         trustedSenders[sender] = trusted;
//         emit TrustedSenderUpdated(sender, trusted);
//     }

//     function pause() external onlyOwner {
//         _pause();
//     }

//     function unpause() external onlyOwner {
//         _unpause();
//     }

//     // Message handling
//     function handleMessage(
//         bytes32 messageId,
//         uint32 sourceChainId,
//         address sender,
//         bytes calldata message
//     ) external nonReentrant whenNotPaused {
//         require(trustedSources[sourceChainId], "Untrusted source chain");
//         require(trustedSenders[sender], "Untrusted sender");
//         require(!processedMessages[messageId], "Message already processed");

//         // Verify message through relay
//         require(
//             relay.verifyMessage(messageId, sourceChainId, sender, message),
//             "Message verification failed"
//         );

//         // Mark message as processed
//         processedMessages[messageId] = true;

//         // Process the message
//         _processMessage(messageId, sourceChainId, sender, message);

//         emit MessageProcessed(messageId, sourceChainId, sender, message);
//     }

//     // Internal message processing logic
//     function _processMessage(
//         bytes32 messageId,
//         uint32 sourceChainId,
//         address sender,
//         bytes calldata message
//     ) internal virtual {
//         // Override this function to implement specific message handling logic
//     }
// }
