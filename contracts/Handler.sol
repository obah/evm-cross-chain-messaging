//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/*
 *This contract will be deployed on ethereum sepolia
 *It handles the message generated from Dispatcher
 *Then emits the an handled event if successful
 */
contract Handler {
    error InvalidAddress();
    error CallFailed();

    event Handled(address indexed sender, bytes message, uint256 messageId);

    function handle(
        address _userAddress,
        bytes memory _message,
        address _target,
        uint256 _messageId
    ) external payable returns (bytes memory) {
        //make the calls here
        if (_target == address(0)) revert InvalidAddress();

        (bool success, bytes memory data) = _target.call{value: msg.value}(
            _message
        );

        if (!success) revert CallFailed();

        emit Handled(_userAddress, _message, _messageId);

        return data;
    }

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
