// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SecurityTokenUpgradeable} from "../../SecurityTokenUpgradeable.sol";

contract SecurityToken_V1 is SecurityTokenUpgradeable {
    constructor(string memory version) SecurityTokenUpgradeable(version) {
    }
}