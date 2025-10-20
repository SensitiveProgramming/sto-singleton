// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {GatewayUpgradeable} from "../../GatewayUpgradeable.sol";

contract Gateway_V1 is GatewayUpgradeable {
    constructor(string memory version) GatewayUpgradeable(version) {
    }
}