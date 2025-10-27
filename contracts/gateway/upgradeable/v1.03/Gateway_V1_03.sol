// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Gateway_V1_02} from "../v1.02/Gateway_V1_02.sol";

contract Gateway_V1_03 is Gateway_V1_02 {
    address internal _currency;

    constructor(string memory version) Gateway_V1_02(version) {
    }

    function reinitialize(address currencyToken) public reinitializer(2) {
        _currency = currencyToken;
    }

    function getCurrencyBalanceByAddress(address acntAddress) external virtual returns (uint256 balance) {
        balance = IERC20(_currency).balanceOf(acntAddress);
    }

    function getCurrencyBalanceByAccount(bytes32 ittNo, bytes32 acntNo) external virtual returns (uint256 balance) {
        address acntAddress = _checkAcntNo(ittNo, acntNo);
        balance = IERC20(_currency).balanceOf(acntAddress);
    }
}