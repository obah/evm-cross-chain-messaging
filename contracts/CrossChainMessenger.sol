//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract CrossChainMessenger is Pausable, ReentrancyGuard {
    error UnsupportedChain();
    error InvalidAddress();
    error MessageProcessed();
    error VerificationFailed();
    error CallFailed();
    error Unathorized();

    event MessageSent(
        address to,
        uint32 toChainId,
        bytes messageData,
        address indexed sender,
        uint256 indexed messageId,
        bytes32 indexed messageHash
    );

    event ChainStatusUpdated(uint32 chainId, bool supported);

    event MessageReceived(
        address indexed from,
        uint32 fromChainId,
        bytes message,
        uint256 indexed messageId
    );

    struct Message {
        uint32 sourceChainId;
        uint32 destinationChainId;
        address sender;
        address recipient;
        bytes message;
    }

    address public immutable OWNER;

    uint256 public nonce;

    mapping(bytes32 => bool) public sentMessages;
    mapping(uint32 => bool) public supportedChains;
    mapping(bytes32 => bool) public processedMessages;
    mapping(bytes32 => Message) public messages;

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert Unathorized();
        _;
    }

    constructor() {
        OWNER = msg.sender;
    }

    //todo implement bridge later using across
    // function bridge() external {};

    function sendMessage(
        address _userAddress,
        uint32 _toChainId,
        bytes memory _message,
        address _toAddress
    ) external payable returns (bytes32) {
        if (!supportedChains[_toChainId]) revert UnsupportedChain();
        if (_toAddress == address(0)) revert InvalidAddress();

        nonce += 1;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                block.chainid,
                _toChainId,
                _userAddress,
                _toAddress,
                nonce,
                _message
            )
        );

        sentMessages[messageHash] = true;

        Message storage message = messages[messageHash];

        message.sourceChainId = uint32(block.chainid);
        message.destinationChainId = _toChainId;
        message.sender = _userAddress;
        message.recipient = _toAddress;
        message.message = _message;

        emit MessageSent(
            _toAddress,
            _toChainId,
            _message,
            _userAddress,
            nonce,
            messageHash
        );

        return messageHash;
    }

    function receiveMessage(
        address _userAddress,
        bytes calldata _message,
        address _targetAddress,
        uint256 _messageId,
        uint32 _fromChainId,
        bytes32 _messageHash
    ) external payable nonReentrant whenNotPaused returns (bytes memory) {
        if (!supportedChains[_fromChainId]) revert UnsupportedChain();
        if (processedMessages[_messageHash]) revert MessageProcessed();
        if (_targetAddress == address(0)) revert InvalidAddress();

        // bool verify = _verifyMessage(
        //     _messageHash,
        //     _fromChainId,
        //     _userAddress,
        //     _message
        // );

        // if (!verify) revert VerificationFailed();

        processedMessages[_messageHash] = true;

        (bool success, bytes memory data) = _targetAddress.call{
            value: msg.value
        }(_message);

        if (!success) revert CallFailed();

        emit MessageReceived(_userAddress, _fromChainId, _message, _messageId);

        return data;
    }

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

    // function _verifyMessage(
    //     bytes32 _messageHash,
    //     uint32 _sourceChainId,
    //     address _userAddress,
    //     bytes calldata _message
    // ) internal view returns (bool) {
    //     Message storage message = messages[_messageHash];

    //     return (message.sourceChainId == _sourceChainId &&
    //         message.sender == _userAddress &&
    //         keccak256(message.message) == keccak256(_message));
    // }

    function getFunctionBytes(
        string memory _functionSig,
        uint256 _param
    ) external pure returns (bytes memory) {
        bytes memory functionBytes = abi.encodeWithSignature(
            _functionSig,
            _param
        );

        return functionBytes;
    }
}
