// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Gateway_V1_04} from "../v1.04/Gateway_V1_04.sol";
import {DoublyLinkedList} from "../../../utils/structs/DoublyLinkedList.sol";
import {SecurityToken_V1_01} from "../../../token/security/upgradeable/v1.01/SecurityToken_V1_01.sol";

contract Gateway_V1_05 is Gateway_V1_04 {
    constructor(string memory version) Gateway_V1_04(version) {
    }

    function accountQueryBalance(bytes32 ittNo, bytes32 acntNo) external view virtual override returns (bytes32, bytes32, bytes32[] memory, bytes32[][] memory, uint256[][] memory, uint256[][] memory, bytes32[][] memory) {
        address acntAddress = _checkAcntNo(ittNo, acntNo);
        uint256 length = DoublyLinkedList.length(_acntTokens[ittNo][acntNo]);
        bytes32[] memory isuNo = DoublyLinkedList.getAllList(_acntTokens[ittNo][acntNo]);
        bytes32[][] memory balTp = new bytes32[][](length*9);
        uint256[][] memory bf = new uint256[][](length*9);
        uint256[][] memory curr = new uint256[][](length*9);

        for (uint256 i=0; i<length; i++) {
            address tokenAddress = _checkIsuNo(isuNo[i]);
            (balTp[i], bf[i], curr[i]) = SecurityToken_V1_01(tokenAddress).allBalanceOfBf(acntAddress);
        }

        // uint256[][] memory bf = curr;
        bytes32[][] memory txid = new bytes32[][](length*9);

        return (ittNo, acntNo, isuNo, balTp, curr, bf, txid);
    }

    function accountQueryBalanceByIsuNo(bytes32 ittNo, bytes32 isuNo, bytes32 acntNo) external view virtual override returns (bytes32, bytes32, bytes32, bytes32, bytes32[] memory, uint256[] memory, uint256[] memory, bytes32[] memory) {
        address tokenAddress = _checkIsuNo(isuNo);
        address acntAddress = _checkAcntNo(ittNo, acntNo);

        (bytes32[] memory balTp, uint256[] memory bf, uint256[] memory curr) = SecurityToken_V1_01(tokenAddress).allBalanceOfBf(acntAddress);

        bytes32[] memory txid = new bytes32[](9);

        return (ittNo, acntNo, _acntTp[ittNo][acntNo], isuNo, balTp, curr, bf, txid);
    }
}