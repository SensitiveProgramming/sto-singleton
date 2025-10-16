// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract STOUpgradeable is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 private immutable VERSION;
    bytes32 public constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;


    constructor(string memory version) {
        VERSION = bytes32(abi.encodePacked(version));
    }


    function getVersion() external view virtual returns (string memory) {
        return string(abi.encodePacked(VERSION));
    }

    function getImplementation() external view virtual returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}