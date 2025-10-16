// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {STOSelectableUpgradeable} from "../../proxy/utils/STOSelectableUpgradeable.sol";
import {IERC20Lock} from "../extension/IERC20Lock.sol";

contract SecurityTokenUpgradeable is Initializable, ERC20Upgradeable, STOSelectableUpgradeable, IERC20Lock {
    mapping (address => uint256) private _lockedBalances;

    constructor(string memory version) STOSelectableUpgradeable(version) {
        _disableInitializers();
    }

    function initialize(string memory stName, string memory stSymbol) public initializer {
        __ERC20_init(stName, stSymbol);
        __UUPSUpgradeable_init();
    }

    function issue(address to, uint256 amount) external virtual {
        _mint(to, amount);
    }

    function lockedBalanceOf(address account) public view virtual override returns (uint256) {
        return _lockedBalances[account];
    }

    function lock(address account, uint256 lockAmount) public virtual override {
        uint256 balance = balanceOf(account);
        uint256 canLockBalance = balance - _lockedBalances[account];

        if (balance < lockAmount) {
            revert InsufficientBalance(account, balance, lockAmount);
        } else if (canLockBalance < lockAmount) {
            revert InsufficientCanLockBalance(account, canLockBalance, lockAmount);
        }

        _lockedBalances[account] += lockAmount;
        emit Lock(account, lockAmount, _lockedBalances[account]);
    }

    function unlock(address account, uint256 unlockAmount) public virtual override {
        _checkCanUnlock(account, unlockAmount);
        _lockedBalances[account] -= unlockAmount;
        emit Unlock(account, unlockAmount, _lockedBalances[account]);
    }

    function unlockTransfer(address from, address to, uint256 unlockAmount) external virtual override {
        unlock(from, unlockAmount);
        _update(from, to, unlockAmount);
    }

    function unlockTransferWithFee(address from, address to, address feeAddress, uint256 unlockAmount, uint256 fromFee, uint256 toFee) external virtual override {
        unlock(from, unlockAmount);

        if (fromFee > 0) {
            _update(from, feeAddress, fromFee);
            _update(from, to, unlockAmount - fromFee);
        } else {
            _update(from, to, unlockAmount);
        }

        if (toFee > 0) {
            _update(to, feeAddress, toFee);
        }
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        if (from != address(0)) {
            _checkCanTransfer(from, value);
        }

        super._update(from, to, value);
    }

    function _checkCanTransfer(address account, uint256 amount) internal view {
        uint256 canTransferAmount = balanceOf(account) - _lockedBalances[account];

        if (canTransferAmount < amount) {
            revert InsufficientTransferAmount(account, canTransferAmount, amount);
        }
    }

    function _checkCanUnlock(address account, uint256 unlockAmount) internal view {
        if (lockedBalanceOf(account) < unlockAmount) {
            revert InsufficientLockedBalance(account, _lockedBalances[account], unlockAmount);
        }
    }
}

// import {ERC20Lock} from "../extension/ERC20Lock.sol";

// contract SecurityToken is ERC20Lock {
//     bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

//     constructor(address locker) ERC20Lock("SecurityToken", "ST") {
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
//         _grantRole(ISSUER_ROLE, _msgSender());
//         _grantRole(LOCKER_ROLE, locker);
//     }

//     function issue(address to, uint256 amount) external virtual onlyRole(ISSUER_ROLE) {
//         _mint(to, amount);
//     }
// }