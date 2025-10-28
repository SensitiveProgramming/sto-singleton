// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {STOSelectableUpgradeable} from "../../proxy/utils/STOSelectableUpgradeable.sol";
import {IERC20Lock} from "../extension/IERC20Lock.sol";
import {DoublyLinkedList} from "../../utils/structs/DoublyLinkedList.sol";
import {IWhitelist} from "../../utils/whitelist/IWhitelist.sol";


contract SecurityTokenUpgradeable is STOSelectableUpgradeable, IERC20Lock {
    /// 잔고유형(BalTp)
    bytes32 public constant BalTp_00 = bytes32("00");   // 일반
    bytes32 public constant BalTp_11 = bytes32("11");   // 질권
    bytes32 public constant BalTp_12 = bytes32("12");   // 압류
    bytes32 public constant BalTp_13 = bytes32("13");   // 전자등록증명
    bytes32 public constant BalTp_14 = bytes32("14");   // 소유자증명
    bytes32 public constant BalTp_15 = bytes32("15");   // 소유자증명통지
    bytes32 public constant BalTp_21 = bytes32("21");   // 전자등록말소청구
    bytes32 public constant BalTp_31 = bytes32("31");   // 유통제한
    bytes32 public constant BalTp_99 = bytes32("99");   // 매도주문대기 (신규)

    /// variables
    mapping (address => uint256) internal _balances;
    mapping (bytes32 => uint256) internal _ittBalances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;

    bytes32[] internal _partitionList;
    mapping (bytes32 => uint256) internal _indexAllPartitions;
    mapping (address => bytes32[]) internal _accountPartitions;
    mapping (address => mapping(bytes32 => uint256)) internal _indexAccountPartitions;
    mapping (bytes32 => mapping(address => uint256)) internal _partitionBalances;

    DoublyLinkedList.AddressList internal _holderList;
    address internal _whitelist;

    event Issue(address indexed to, uint256 value);
    event Redeem(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    error InsufficientPartitionBalance(bytes32 partition, address account, uint256 balance, uint256 needed);
    error SenderNotInWhitelist(address sender);
    error ReceiverNotInWhitelist(address receiver);

    constructor(string memory version) STOSelectableUpgradeable(version) {

    }

    function initialize(string memory stName, address whitelist) public initializer {
        __UUPSUpgradeable_init();
        _name = stName;
        _symbol = _name;
        _whitelist = whitelist;

        _partitionList.push(BalTp_00);
        _indexAllPartitions[BalTp_00] = _partitionList.length;
        _partitionList.push(BalTp_11);
        _indexAllPartitions[BalTp_11] = _partitionList.length;
        _partitionList.push(BalTp_12);
        _indexAllPartitions[BalTp_12] = _partitionList.length;
        _partitionList.push(BalTp_13);
        _indexAllPartitions[BalTp_13] = _partitionList.length;
        _partitionList.push(BalTp_14);
        _indexAllPartitions[BalTp_14] = _partitionList.length;
        _partitionList.push(BalTp_15);
        _indexAllPartitions[BalTp_15] = _partitionList.length;
        _partitionList.push(BalTp_21);
        _indexAllPartitions[BalTp_21] = _partitionList.length;
        _partitionList.push(BalTp_31);
        _indexAllPartitions[BalTp_31] = _partitionList.length;
        _partitionList.push(BalTp_99);
        _indexAllPartitions[BalTp_99] = _partitionList.length;
    }

    function issue(bytes32 partition, address account, uint256 qty) external virtual {
        _update(bytes32(bytes("")), address(0), partition, account, qty);
        emit Issue(account, qty);
    }

    function redeem(bytes32 partition, address account, uint256 qty) external virtual {
        _update(partition, account, bytes32(bytes("")), address(0), qty);
        emit Redeem(account, qty);
    }

    function transfer(bytes32 partitionFrom, address accountFrom, bytes32 partitionTo, address accountTo, uint256 qty) public virtual {
        _update(partitionFrom, accountFrom, partitionTo, accountTo, qty);
        emit Transfer(accountFrom, accountTo, qty);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function allBalanceOf(address account) external view virtual returns (bytes32[] memory, uint256[] memory) {
        bytes32[] memory balTp = new bytes32[](9);
        uint256[] memory balances = new uint256[](9);

        balTp[0] = BalTp_00;
        balTp[1] = BalTp_11;
        balTp[2] = BalTp_12;
        balTp[3] = BalTp_13;
        balTp[4] = BalTp_14;
        balTp[5] = BalTp_15;
        balTp[6] = BalTp_21;
        balTp[7] = BalTp_31;
        balTp[8] = BalTp_99;

        for(uint256 i=0; i<9; i++) {
            balances[i] = _partitionBalances[balTp[i]][account];
        }

        return (balTp, balances);
    }

    function lock(address account, uint256 lockAmount) public virtual override {
        uint256 balance = _balances[account];
        uint256 canLockBalance = _partitionBalances[BalTp_00][account];

        if (_balances[account] < lockAmount) {
            revert InsufficientBalance(account, balance, lockAmount);
        } else if (canLockBalance < lockAmount) {
            revert InsufficientCanLockBalance(account, canLockBalance, lockAmount);
        }

        _update(BalTp_00, account, BalTp_99, account, lockAmount);
        emit Lock(account, lockAmount, _partitionBalances[BalTp_99][account]);
    }

    function unlock(address account, uint256 unlockAmount) public virtual override {
        _checkCanUnlock(account, unlockAmount);
        _update(BalTp_99, account, BalTp_00, account, unlockAmount);
        emit Unlock(account, unlockAmount, _partitionBalances[BalTp_99][account]);
    }

    function unlockTransfer(address from, address to, uint256 unlockAmount) external virtual override {
        unlock(from, unlockAmount);
        transfer(BalTp_00, from, BalTp_00, to, unlockAmount);
    }

    function unlockTransferWithFee(address from, address to, address feeAddress, uint256 unlockAmount, uint256 fromFee, uint256 toFee) external virtual override {
        unlock(from, unlockAmount);

        if (fromFee > 0) {
            transfer(BalTp_99, from, BalTp_99, feeAddress, fromFee);
            transfer(BalTp_99, from, BalTp_99, to, unlockAmount - fromFee);
        } else {
            transfer(BalTp_99, from, BalTp_99, to, unlockAmount);
        }

        if (toFee > 0) {
            transfer(BalTp_99, to, BalTp_99, feeAddress, toFee);
        }
    }

    function lockedBalanceOf(address account) public view virtual override returns (uint256) {
        return _partitionBalances[BalTp_99][account];
    }

    function _update(bytes32 partitionFrom, address accountFrom, bytes32 partitionTo, address accountTo, uint256 qty) internal virtual {
        ( bool statusFrom, bytes32 ittFrom, ) = IWhitelist(_whitelist).getAddressInfo(accountFrom);
        ( bool statusTo, bytes32 ittTo, ) = IWhitelist(_whitelist).getAddressInfo(accountTo);

        if (accountFrom == address(0)) {
            _totalSupply += qty;
        } else {
            if (!statusFrom) {
                revert SenderNotInWhitelist(accountFrom);
            }

            if (_partitionBalances[partitionFrom][accountFrom] < qty) {
                revert InsufficientPartitionBalance(partitionFrom, accountFrom, _partitionBalances[partitionFrom][accountFrom], qty);
            }

            _partitionBalances[partitionFrom][accountFrom] -= qty;
            _balances[accountFrom] -= qty;
            _ittBalances[ittFrom] -= qty;
 
            if (_balances[accountFrom] == 0 && DoublyLinkedList.exists(_holderList, accountFrom)) {
                DoublyLinkedList.remove(_holderList, accountFrom);
            }
        }

        if (accountTo == address(0)) {
            _totalSupply -= qty;
        } else {
            if (!statusTo) {
                revert ReceiverNotInWhitelist(accountFrom);
            }

            if (_indexAllPartitions[partitionTo] == 0) {
                _partitionList.push(partitionTo);
                _indexAllPartitions[partitionTo] = _partitionList.length;
            }

            if (_indexAccountPartitions[accountTo][partitionTo] == 0) {
                _accountPartitions[accountTo].push(partitionTo);
                _indexAccountPartitions[accountTo][partitionTo] = _accountPartitions[accountTo].length;
            }

            _partitionBalances[partitionTo][accountTo] += qty;
            _balances[accountTo] += qty;
            _ittBalances[ittTo] += qty;

            if (qty > 0 && !DoublyLinkedList.exists(_holderList, accountTo)) {
                DoublyLinkedList.insert(_holderList, accountTo);
            }
        }
    }

    function _checkCanUnlock(address account, uint256 unlockAmount) internal view {
        uint256 lockedBalance = lockedBalanceOf(account);
        if (lockedBalance < unlockAmount) {
            revert InsufficientLockedBalance(account, lockedBalance, unlockAmount);
        }
    }
}

// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// import {STOSelectableUpgradeable} from "../../proxy/utils/STOSelectableUpgradeable.sol";
// import {IERC20Lock} from "../extension/IERC20Lock.sol";
// import {STOUpgradeable} from "../proxy/utils/STOUpgradeable.sol";


// contract SecurityTokenUpgradeable is Initializable, ERC20Upgradeable, STOSelectableUpgradeable, IERC20Lock {
//     mapping (address => uint256) private _lockedBalances;

//     constructor(string memory version) STOSelectableUpgradeable(version) {
//         _disableInitializers();
//     }

//     function initialize(string memory stName, string memory stSymbol) public initializer {
//         __ERC20_init(stName, stSymbol);
//         __UUPSUpgradeable_init();
//     }

//     function issue(address to, uint256 amount) external virtual {
//         _mint(to, amount);
//     }

//     function lockedBalanceOf(address account) public view virtual override returns (uint256) {
//         return _lockedBalances[account];
//     }

//     function lock(address account, uint256 lockAmount) public virtual override {
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

//     function unlock(address account, uint256 unlockAmount) public virtual override {
//         _checkCanUnlock(account, unlockAmount);
//         _lockedBalances[account] -= unlockAmount;
//         emit Unlock(account, unlockAmount, _lockedBalances[account]);
//     }

//     function unlockTransfer(address from, address to, uint256 unlockAmount) external virtual override {
//         unlock(from, unlockAmount);
//         _update(from, to, unlockAmount);
//     }

//     function unlockTransferWithFee(address from, address to, address feeAddress, uint256 unlockAmount, uint256 fromFee, uint256 toFee) external virtual override {
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