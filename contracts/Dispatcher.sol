//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Dispatcher {
    event Dispatched(
        uint32 destinationChain,
        address sender,
        bytes message,
        bytes32 indexed messageBytes,
        uint256 indexed messageId
    );

    struct Message {
        address userAddress;
        uint32 chainId;
        bytes message;
        uint256 value;
        address targetAddress;
    }

    uint256 counter;

    mapping(uint256 => Message) messages;

    //implement bridge later using across

    function dispatch(
        address _userAddress,
        uint32 _chainId,
        bytes memory _message,
        address _target
    ) external payable returns (bytes32) {
        counter += 1;

        Message storage message = messages[counter];

        message.message = _message;
        message.userAddress = _userAddress;
        message.chainId = _chainId;
        message.targetAddress = _target;
        message.value = msg.value;

        bytes32 messageId = keccak256(
            abi.encodePacked(
                block.chainid,
                _chainId,
                msg.sender,
                _target,
                counter,
                _message
            )
        );

        emit Dispatched(_chainId, _userAddress, _message, messageId, counter);

        return messageId;
    }

    function getMessage(uint256 msgId) external view returns (Message memory) {
        return messages[msgId];
    }
}
