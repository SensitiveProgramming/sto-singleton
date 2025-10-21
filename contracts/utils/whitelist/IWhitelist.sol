// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Whitelist 컨트랙트 인터페이스
interface IWhitelist {
    function addAccount(bytes32 ittNo, bytes32 acntNo, address acntAddress) external;
    function removeAccount(bytes32 ittNo, bytes32 acntNo) external;
    function getAccountAddress(bytes32 ittNo, bytes32 acntNo) external view returns (bool status, address acntAddress);
    function getAddressInfo(address acntAddress) external view returns (bool status, bytes32 ittNo, bytes32 acntNo);

    event AccountAdded(bytes32 ittNo, bytes32 acntNo, address acntAddress);
    event AccountRemoved(bytes32 ittNo, bytes32 acntNo, address acntAddress);

    error DuplicateAccount(bytes32 ittNo, bytes32 acntNo);
}