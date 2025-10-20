// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IWhitelist} from "./IWhitelist.sol";

/**
 * @title Whitelist 관리 컨트랙트
 * @notice 특정 고객/기관을 관리하기 위한 컨트랙트
 */
contract Whitelist is IWhitelist {
    mapping (bytes32 => mapping (bytes32 => address)) private _acntAddress;
    mapping (address => bool) private _status;
    mapping (address => bytes32) private _ittNo;
    mapping (address => bytes32) private _acntNo;

    constructor() {
    }

    function addAccount(bytes32 ittNo, bytes32 acntNo, address acntAddress) external virtual override {
        address tmpAddress = _acntAddress[ittNo][acntNo];
        if (tmpAddress != address(0) && tmpAddress != acntAddress) {
            revert DuplicateAccount(ittNo, acntNo);
        } else if (tmpAddress == acntAddress) {
            return;
        }

        _acntAddress[ittNo][acntNo] = acntAddress;
        _status[acntAddress] = true;
        _ittNo[acntAddress] = ittNo;
        _acntNo[acntAddress] = acntNo;
        emit AccountAdded(ittNo, acntNo, acntAddress);
    }

    function removeAccount(bytes32 ittNo, bytes32 acntNo) external virtual override {
        address tmpAddress = _acntAddress[ittNo][acntNo];
        if (tmpAddress == address(0)) {
            return;
        }

        _acntAddress[ittNo][acntNo] = address(0);
        _status[tmpAddress] = false;
        _ittNo[tmpAddress] = bytes32("");
        _acntNo[tmpAddress] = bytes32("");
        emit AccountRemoved(ittNo, acntNo, _acntAddress[ittNo][acntNo]);
    }

    function getAccountAddress(bytes32 ittNo, bytes32 acntNo) external view virtual override returns (bool, address) {
        address tmpAddress = _acntAddress[ittNo][acntNo];
        return (_status[tmpAddress], tmpAddress);
    }

    function getAddressInfo(address acntAddress) external view virtual override returns (bool, bytes32, bytes32) {
        return (_status[acntAddress], _ittNo[acntAddress], _acntNo[acntAddress]);
    }
}