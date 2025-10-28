// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SecurityToken_V1} from "../v1/SecurityToken_V1.sol";
import {DoublyLinkedList} from "../../../../utils/structs/DoublyLinkedList.sol";
import {IWhitelist} from "../../../../utils/whitelist/IWhitelist.sol";


contract SecurityToken_V1_01 is SecurityToken_V1 {
    mapping (address => uint256) internal _bfBalances;
    mapping (bytes32 => mapping(address => uint256)) internal _bfPartitionBalances;

    constructor(string memory version) SecurityToken_V1(version) {
    }

    function allBalanceOfBf(address account) external view virtual returns (bytes32[] memory, uint256[] memory, uint256[] memory) {
        bytes32[] memory balTp = new bytes32[](9);
        uint256[] memory bfBalances = new uint256[](9);
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
            bfBalances[i] = _bfPartitionBalances[balTp[i]][account];
            balances[i] = _partitionBalances[balTp[i]][account];
        }

        return (balTp, bfBalances, balances);
    }

    function _update(bytes32 partitionFrom, address accountFrom, bytes32 partitionTo, address accountTo, uint256 qty) internal virtual override {
        (bool statusFrom, bytes32 ittFrom, ) = IWhitelist(_whitelist).getAddressInfo(accountFrom);
        (bool statusTo, bytes32 ittTo, ) = IWhitelist(_whitelist).getAddressInfo(accountTo);

        if (accountFrom == address(0)) {
            _totalSupply += qty;
        } else {
            if (!statusFrom) {
                revert SenderNotInWhitelist(accountFrom);
            }

            if (_partitionBalances[partitionFrom][accountFrom] < qty) {
                revert InsufficientPartitionBalance(partitionFrom, accountFrom, _partitionBalances[partitionFrom][accountFrom], qty);
            }

            _bfPartitionBalances[partitionFrom][accountFrom] = _partitionBalances[partitionFrom][accountFrom];
            _partitionBalances[partitionFrom][accountFrom] -= qty;
            _bfBalances[accountFrom] = _balances[accountFrom];
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

            _bfPartitionBalances[partitionTo][accountTo] = _partitionBalances[partitionTo][accountTo];
            _partitionBalances[partitionTo][accountTo] += qty;
            _bfBalances[accountTo] = _balances[accountTo];
            _balances[accountTo] += qty;
            _ittBalances[ittTo] += qty;

            if (qty > 0 && !DoublyLinkedList.exists(_holderList, accountTo)) {
                DoublyLinkedList.insert(_holderList, accountTo);
            }
        }
    }
}