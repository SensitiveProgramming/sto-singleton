// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Lock} from "./IERC20Lock.sol";

contract ERC20Lock is ERC20, IERC20Lock {
    mapping (address => uint256) private _lockedBalances;

    constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol){
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

// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
// import {IERC20Lock} from "./IERC20Lock.sol";

// contract ERC20Lock is ERC20, AccessControl, IERC20Lock {
//     bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

//     mapping (address => uint256) private _lockedBalances;

//     constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol){
//     }

//     function lockedBalanceOf(address account) public view virtual override returns (uint256) {
//         return _lockedBalances[account];
//     }

//     function lock(address account, uint256 lockAmount) public virtual override onlyRole(LOCKER_ROLE) {
//         uint256 balance = balanceOf(account);
//         uint256 canLockBalance = balance - _lockedBalances[account];

//         if (balance < lockAmount) {
//             revert InsufficientBalance(account, balance, lockAmount);
//         } else if (canLockBalance < lockAmount) {
//             revert InsufficientCanLockBalance(account, canLockBalance, lockAmount);
//         }

//         _lockedBalances[account] += lockAmount;
//         emit Lock(account, lockAmount, _lockedBalances[account]);
//     }

//     function unlock(address account, uint256 unlockAmount) public virtual override onlyRole(LOCKER_ROLE) {
//         _checkCanUnlock(account, unlockAmount);
//         _lockedBalances[account] -= unlockAmount;
//         emit Unlock(account, unlockAmount, _lockedBalances[account]);
//     }

//     function unlockTransfer(address from, address to, uint256 unlockAmount) external virtual override onlyRole(LOCKER_ROLE) {
//         unlock(from, unlockAmount);
//         _update(from, to, unlockAmount);
//     }

//     function unlockTransferWithFee(address from, address to, address feeAddress, uint256 unlockAmount, uint256 fromFee, uint256 toFee) external virtual override onlyRole(LOCKER_ROLE) {
//         unlock(from, unlockAmount);

//         if (fromFee > 0) {
//             _update(from, feeAddress, fromFee);
//             _update(from, to, unlockAmount - fromFee);
//         } else {
//             _update(from, to, unlockAmount);
//         }

//         if (toFee > 0) {
//             _update(to, feeAddress, toFee);
//         }
//     }

//     function _update(address from, address to, uint256 value) internal virtual override {
//         if (from != address(0)) {
//             _checkCanTransfer(from, value);
//         }

//         super._update(from, to, value);
//     }

//     function _checkCanTransfer(address account, uint256 amount) internal view {
//         uint256 canTransferAmount = balanceOf(account) - _lockedBalances[account];

//         if (canTransferAmount < amount) {
//             revert InsufficientTransferAmount(account, canTransferAmount, amount);
//         }
//     }

//     function _checkCanUnlock(address account, uint256 unlockAmount) internal view {
//         if (lockedBalanceOf(account) < unlockAmount) {
//             revert InsufficientLockedBalance(account, _lockedBalances[account], unlockAmount);
//         }
//     }
// }