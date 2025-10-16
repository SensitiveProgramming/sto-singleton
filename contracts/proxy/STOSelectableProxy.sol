// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {STOProxyUtils} from "./utils/STOProxyUtils.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {STOBeacon} or local
 * implementation storage slot `uint256(keccak256('eip1967.proxy.implementation')) - 1`.
 * 
 * The beacon address {STOBeacon} is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that
 * it doesn't conflict with the storage layout of the implementation behind the proxy.
 * 
 * 
 * {STOSelectableProxy} operates in two modes: beacon mode and non-beacon mode.
 * 
 * In beacon mode {STOSelectableProxy} gets implementation address through beacon {STOBeacon}.
 * 
 * In non-beacon mode {STOSelectableProxy} gets implementation address from local implementation storage slot 
 * `uint256(keccak256('eip1967.proxy.implementation')) - 1`.
 */
contract STOSelectableProxy is Proxy {
    /**
     * @dev Initializes the selectable and upgradeable proxy with an initial implementation specified by `implementation`.
     *
     * If `operationMode` is true, `beacon` must be nonempty.
     * If `operationMode` is false, `localImplementation` must be nonempty.
     */
    constructor(bool operationMode, address beacon, address localImplementation, bytes memory data) payable {
        if(operationMode) {
            STOProxyUtils.setToBeaconModeAndCall(beacon, data);
        } else {
            STOProxyUtils.setToNonBeaconModeAndCall(localImplementation, data);
        }
    }

    /**
     * @dev Returns the current implementation address.
     * 
     * @notice The Returned address varies depending on the operation mode.
     * Beacon mode: Gets implementation address from beacon {STOBeacon}.
     * Non-beacon mode: Gets implementation address from local implementation storage slot 
     * `uint256(keccak256('eip1967.proxy.implementation')) - 1`.
     */
    function _implementation() internal view virtual override returns (address) {
        return STOProxyUtils.getImplementation();
    }
}
