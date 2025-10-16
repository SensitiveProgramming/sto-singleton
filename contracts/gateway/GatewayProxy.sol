// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {STOProxy} from "../proxy/STOProxy.sol";

contract GatewayProxy is STOProxy {
    constructor(address implementation) STOProxy(implementation, "") {

    }
}