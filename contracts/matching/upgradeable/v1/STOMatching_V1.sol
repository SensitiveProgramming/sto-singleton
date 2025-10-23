// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title 다자간상대매매 매칭엔진 컨트랙트
import {STOMatchingUpgradeable} from "../../STOMatchingUpgradeable.sol";

contract STOMatching_V1 is STOMatchingUpgradeable {
    constructor(string memory version) STOMatchingUpgradeable(version) {
    }
}