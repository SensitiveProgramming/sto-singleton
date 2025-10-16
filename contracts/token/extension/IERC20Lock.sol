// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Lock {
    function lock(address account, uint256 lockAmount) external;
    function unlock(address account, uint256 unlockAmount) external;
    function unlockTransfer(address from, address to, uint256 unlockAmount) external;
    function unlockTransferWithFee(address from, address to, address feeAddress, uint256 unlockAmount, uint256 fromFee, uint256 toFee) external;
    function lockedBalanceOf(address account) external view returns (uint256 lockedBalance);

    event Lock(address indexed account, uint256 lockAmount, uint256 lockedBalance);
    event Unlock(address indexed account, uint256 unlockAmount, uint256 lockedBalance);

    error InsufficientBalance(address account, uint256 balance, uint256 lockAmount);
    error InsufficientCanLockBalance(address account, uint256 canLockBalance, uint256 lockAmount);
    error InsufficientLockedBalance(address account, uint256 lockedAmount, uint256 unlockAmount);
    error InsufficientTransferAmount(address account, uint256 canTransferAmount, uint256 transferAmount);
}