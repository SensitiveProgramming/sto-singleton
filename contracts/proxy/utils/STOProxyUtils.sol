// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBeacon, StorageSlot, ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

library STOProxyUtils {
    /**
     * @dev Emitted when the operation mode has changed to 'beacon mode'.
     */
    event BeaconMode(address operator, address beacon, address implementation);

    /**
     * @dev Emitted when the operation mode has changed to 'Non-beacon mode'.
     */
    event NonBeaconMode(address operator, address implementation);

    /**
     * @dev Storage slot with the operation mode of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.operationMode" subtracted by 1.
     */
    bytes32 internal constant OPERATION_MODE_SLOT = 0xcd840a391ffd9edd8e216df0e408188797005606f67622d2b6249923b5505252;

    /**
     * @dev Returns the current implementation address.
     * 
     * @notice The Returned address varies depending on the operation mode.
     * Beacon mode: Gets implementation address from beacon {STOBeacon}.
     * Non-beacon mode: Gets implementation address from local implementation storage slot 
     * `uint256(keccak256('eip1967.proxy.implementation')) - 1`.
     */
    function getImplementation() internal view returns (address) {
        if (getOperationMode()) {
            return IBeacon(ERC1967Utils.getBeacon()).implementation();
        } else {
            return ERC1967Utils.getImplementation();
        }
    }

    /**
     * @dev Returns the current operation mode.
     * return 'true' when beacon mode and return 'false' when non-beacon mode.
     */
    function getOperationMode() internal view returns (bool) {
        return StorageSlot.getBooleanSlot(OPERATION_MODE_SLOT).value;
    }

    /**
     * @dev Upgrades the beacon and sets the operation mode to `beacon`.
     */
    function setToBeaconModeAndCall(address newBeacon, bytes memory data) internal {
        ERC1967Utils.upgradeBeaconToAndCall(newBeacon, data);
        StorageSlot.getBooleanSlot(OPERATION_MODE_SLOT).value = true;
        emit BeaconMode(msg.sender, newBeacon, IBeacon(newBeacon).implementation());
    }

    /**
     * @dev Upgrades the local implementation and sets the operation mode to `non-beacon`.
     */
    function setToNonBeaconModeAndCall(address newImplementation, bytes memory data) internal {
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
        StorageSlot.getBooleanSlot(OPERATION_MODE_SLOT).value = false;
        emit NonBeaconMode(msg.sender, newImplementation);
    }

    /**
     * @dev Stores the operation mode in the `OPERATION_MODE_SLOT` slot and emits corresponding event.
     */
    function setOperationModeOnly(bool newOperationMode) internal {
        if (newOperationMode) {
            address oldBeacon = ERC1967Utils.getBeacon();
            if (oldBeacon.code.length == 0) {
                revert ERC1967Utils.ERC1967InvalidBeacon(oldBeacon);
            }

            address oldImplementation = IBeacon(oldBeacon).implementation();
            if (oldImplementation.code.length == 0) {
                revert ERC1967Utils.ERC1967InvalidImplementation(oldImplementation);
            }

            StorageSlot.getBooleanSlot(OPERATION_MODE_SLOT).value = true;
            emit BeaconMode(msg.sender, oldBeacon, oldImplementation);
        } else {
            address oldImplementation = ERC1967Utils.getImplementation();
            if (oldImplementation.code.length == 0) {
                revert ERC1967Utils.ERC1967InvalidImplementation(oldImplementation);
            }

            StorageSlot.getBooleanSlot(OPERATION_MODE_SLOT).value = false;
            emit NonBeaconMode(msg.sender, oldImplementation);
        }
    }
}