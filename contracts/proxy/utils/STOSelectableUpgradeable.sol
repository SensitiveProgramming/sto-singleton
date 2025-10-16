// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {STOUpgradeable, ERC1967Utils} from "./STOUpgradeable.sol";
import {STOProxyUtils} from "./STOProxyUtils.sol";


contract STOSelectableUpgradeable is STOUpgradeable {

    constructor(string memory version) STOUpgradeable(version) {}


    function getImplementation() external view override returns (address) {
        return STOProxyUtils.getImplementation();
    }

    function getBeacon() external view returns (address) {
        return ERC1967Utils.getBeacon();
    }

    function getOperationMode() external view returns (bool) {
        return STOProxyUtils.getOperationMode();
    }

    function setToBeaconModeAndCall(address newBeacon, bytes memory data) external payable onlyRole(UPGRADER_ROLE) {
        STOProxyUtils.setToBeaconModeAndCall(newBeacon, data);
    }

    function setToNonBeaconModeAndCall(address newImplementation, bytes memory data) external payable onlyRole(UPGRADER_ROLE) {
        STOProxyUtils.setToNonBeaconModeAndCall(newImplementation, data);
    }

    function setOperationModeOnly(bool oprationMode) external onlyRole(UPGRADER_ROLE) {
        STOProxyUtils.setOperationModeOnly(oprationMode);
    }
}