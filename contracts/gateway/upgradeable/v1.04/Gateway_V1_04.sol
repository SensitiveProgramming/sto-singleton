// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Gateway_V1_03} from "../v1.03/Gateway_V1_03.sol";

contract Gateway_V1_04 is Gateway_V1_03 {
    constructor(string memory version) Gateway_V1_03(version) {
    }

    function getCurrencyBalanceByAddress(address acntAddress) external view virtual override returns (uint256 balance) {
        balance = IERC20(_currency).balanceOf(acntAddress);
    }

    function getCurrencyBalanceByAccount(bytes32 ittNo, bytes32 acntNo) external view virtual override returns (uint256 balance) {
        address acntAddress = _checkAcntNo(ittNo, acntNo);
        balance = IERC20(_currency).balanceOf(acntAddress);
    }

    function getCurrencyToken() external virtual returns (address currencyToken) {
        currencyToken = _currency;
    }
}