// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IGateway} from "./IGateway.sol";
import {MetaDataConstant} from "./MetaDataConstant.sol";
import {STOUpgradeable} from "../proxy/utils/STOUpgradeable.sol";
import {DoublyLinkedList} from "../utils/structs/DoublyLinkedList.sol";

import "../matching/STOMatchingStruct.sol";
import {ISTOMatching} from "../matching/ISTOMatching.sol";
import {IWhitelist} from "../utils/whitelist/IWhitelist.sol";
import {SecurityTokenUpgradeable} from "../token/security/SecurityTokenUpgradeable.sol";
import "../proxy/STOSelectableProxy.sol";

contract GatewayUpgradeable is IGateway, MetaDataConstant, STOUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// Contract
    address internal _stoBeacon;
    address internal _stoMatching;
    address internal _whitelist;

    /// 종목관리
    mapping (bytes32 => address) internal _token;
    mapping (bytes32 => bool) internal _exists;
    mapping (bytes32 => bool) internal _ersYn;
    mapping (bytes32 => bytes32) internal _statusCode;
    
    /// 사용자관리
    mapping (bytes32 => mapping (bytes32 => bytes32)) internal _acntTp;
    mapping (bytes32 => mapping (bytes32 => DoublyLinkedList.Bytes32List)) internal _acntTokens;
    mapping (bytes32 => mapping (bytes32 => DoublyLinkedList.Uint256List)) internal _txList;

    /// 거래관리
    uint256 internal _txid;
    mapping (uint256 => Transaction) internal _transaction;

    constructor(string memory version) STOUpgradeable(version) {
        _disableInitializers();
    }

    function initialize(address stoBeacon, address stoMatching, address whitelist) public virtual initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());

        _stoBeacon = stoBeacon;
        _stoMatching = stoMatching;
        _whitelist = whitelist;
    }


    /** 사용자계좌등록 **/
    function addAccount(bytes32 ittNo, bytes32 acntNo, address acntAddress) external virtual override {
        IWhitelist(_whitelist).addAccount(ittNo, acntNo, acntAddress);
        _acntTp[ittNo][acntNo] = AcntTp_02;
    }

    function removeAccount(bytes32 ittNo, bytes32 acntNo) external virtual override {
         IWhitelist(_whitelist).removeAccount(ittNo, acntNo);
    }

    function addSelfAccount(bytes32 ittNo, bytes32 acntNo, address acntAddress) external virtual override {
        IWhitelist(_whitelist).addAccount(ittNo, acntNo, acntAddress);
        _acntTp[ittNo][acntNo] = AcntTp_01;
    }

    function removeSelfAccount(bytes32 ittNo, bytes32 acntNo) external virtual override {
         IWhitelist(_whitelist).removeAccount(ittNo, acntNo);
    }

    function getAccountAddress(bytes32 ittNo, bytes32 acntNo) external view virtual override returns (bool, address) {
        return IWhitelist(_whitelist).getAccountAddress(ittNo, acntNo);
    }

    function getAddressInfo(address acntAddress) external view virtual override returns (bool, bytes32, bytes32) {
        return IWhitelist(_whitelist).getAddressInfo(acntAddress);
    }


    /** 종목관리 **/
    function tokenRegister(bytes32 isuNo) external virtual override {
        if (_exists[isuNo]) {
            revert("isuNo already exists");
        }

        address sto = address(new STOSelectableProxy(true, _stoBeacon, address(0), ""));
        SecurityTokenUpgradeable(sto).initialize(string(abi.encodePacked(isuNo)), _whitelist);
        _token[isuNo] = sto;
        _exists[isuNo] = true;
        _statusCode[isuNo] = bytes32("00");

        emit TokenRegister(isuNo, sto);
    }

    function tokenQueryInfo(bytes32 isuNo) external view virtual override returns (bytes32 isuNoOut, uint256 totalSupply, bool ersYn, bytes32 statusCode) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        address sto = _token[isuNo];
        return (isuNo, SecurityTokenUpgradeable(sto).totalSupply(), _ersYn[isuNo], _statusCode[isuNo]);
    }


    /** 증권관리 **/
    function balanceStockIn(bytes32 ittNo, bytes32 acntNo, bytes32 acntTp, bytes32 trustYn, bytes32 isuNo, uint256 qty, bytes32 balTp, bytes32 iODtlCode, bytes32 trxCode, bytes32 desc) external virtual override {
        address tokenAddress = _checkIsuNo(isuNo);
        address acntAddress = _checkAcntNo(ittNo, acntNo);

        SecurityTokenUpgradeable(tokenAddress).issue(balTp, acntAddress, qty);

        if (!DoublyLinkedList.exists(_acntTokens[ittNo][acntNo], isuNo)) {
            DoublyLinkedList.insert(_acntTokens[ittNo][acntNo], isuNo);
        }

        emit BalanceStockIn(ittNo, acntNo, acntTp, trustYn, isuNo, qty, balTp, iODtlCode, trxCode, desc);
    }

    function balanceStockOut(bytes32 ittNo, bytes32 acntNo, bytes32 acntTp, bytes32 trustYn, bytes32 isuNo, uint256 qty, bytes32 balTp, bytes32 iODtlCode, bytes32 trxCode, bytes32 desc) external virtual override {
        address tokenAddress = _checkIsuNo(isuNo);
        address acntAddress = _checkAcntNo(ittNo, acntNo);

        SecurityTokenUpgradeable(tokenAddress).redeem(balTp, acntAddress, qty);
        emit BalanceStockOut(ittNo, acntNo, acntTp, trustYn, isuNo, qty, balTp, iODtlCode, trxCode, desc);
    }

    function balanceTransfer(bytes32 ittNo, bytes32 fromAcntNo, bytes32 fromAcntTp, bytes32 fromTrustYn, bytes32 toAcntNo, bytes32 toAcntTp, bytes32 toTrustYn, bytes32 isuNo, uint256 qty, bytes32 desc) external virtual override {
        address tokenAddress = _checkIsuNo(isuNo);
        address fromAcntAddress = _checkAcntNo(ittNo, fromAcntNo);
        address toAcntAddress = _checkAcntNo(ittNo, toAcntNo);

        SecurityTokenUpgradeable(tokenAddress).transfer(fromAcntTp, fromAcntAddress, toAcntTp, toAcntAddress, qty);

        if (!DoublyLinkedList.exists(_acntTokens[ittNo][toAcntNo], isuNo)) {
            DoublyLinkedList.insert(_acntTokens[ittNo][toAcntNo], isuNo);
        }

        emit BalanceTransfer(ittNo, fromAcntNo, fromAcntTp, fromTrustYn, toAcntNo, toAcntTp, toTrustYn, isuNo, qty, desc);
    }

    function balanceTransferToItt(bytes32 fromittNo, bytes32 fromAcntNo, bytes32 fromAcntTp, bytes32 fromTrustYn, bytes32 toittNo, bytes32 toAcntNo, bytes32 toAcntTp, bytes32 toTrustYn, bytes32 isuNo, uint256 qty, bytes32 data, bytes32 desc) external virtual override {
        address tokenAddress = _checkIsuNo(isuNo);
        address fromAcntAddress = _checkAcntNo(fromittNo, fromAcntNo);
        address toAcntAddress = _checkAcntNo(toittNo, toAcntNo);

        SecurityTokenUpgradeable(tokenAddress).transfer(fromAcntTp, fromAcntAddress, toAcntTp, toAcntAddress, qty);

        if (!DoublyLinkedList.exists(_acntTokens[toittNo][toAcntNo], isuNo)) {
            DoublyLinkedList.insert(_acntTokens[toittNo][toAcntNo], isuNo);
        }

        emit BalanceTransferToItt(fromittNo, fromAcntNo, fromAcntTp, fromTrustYn, toittNo, toAcntNo, toAcntTp, toTrustYn, isuNo, qty, data, desc);
    }


    /** 계좌조회 **/
    function accountQueryBalance(bytes32 ittNo, bytes32 acntNo) external view virtual override returns (bytes32, bytes32, bytes32[] memory, bytes32[][] memory, uint256[][] memory, uint256[][] memory, bytes32[][] memory) {
        address acntAddress = _checkAcntNo(ittNo, acntNo);
        uint256 length = DoublyLinkedList.length(_acntTokens[ittNo][acntNo]);
        bytes32[] memory isuNo = DoublyLinkedList.getAllList(_acntTokens[ittNo][acntNo]);
        bytes32[][] memory balTp = new bytes32[][](length*9);
        uint256[][] memory curr = new uint256[][](length*9);

        for (uint256 i=0; i<length; i++) {
            address tokenAddress = _checkIsuNo(isuNo[i]);
            (balTp[i], curr[i]) = SecurityTokenUpgradeable(tokenAddress).allBalanceOf(acntAddress);
        }

        uint256[][] memory bf = curr;
        bytes32[][] memory txid = new bytes32[][](length*9);

        return (ittNo, acntNo, isuNo, balTp, curr, bf, txid);
    }

    function accountQueryBalanceByIsuNo(bytes32 ittNo, bytes32 isuNo, bytes32 acntNo) external view virtual override returns (bytes32, bytes32, bytes32, bytes32, bytes32[] memory, uint256[] memory, uint256[] memory, bytes32[] memory) {
        address tokenAddress = _checkIsuNo(isuNo);
        address acntAddress = _checkAcntNo(ittNo, acntNo);

        (bytes32[] memory balTp, uint256[] memory curr) = SecurityTokenUpgradeable(tokenAddress).allBalanceOf(acntAddress);

        uint256[] memory bf = curr;
        bytes32[] memory txid = new bytes32[](9);

        return (ittNo, acntNo, _acntTp[ittNo][acntNo], isuNo, balTp, curr, bf, txid);
    }

    // function accountQueryTransaction(bytes32 ittNo, bytes32 acntNo, txid) external virtual override returns ()


    /** 거래 **/
    function placeBuyOrder(uint256 orderId, bytes32 ittNo, bytes32 acntNo, bytes32 isuNo, uint256 price, uint256 qty) external virtual override {
        address tokenAddress = _checkIsuNo(isuNo);
        address acntAddress = _checkAcntNo(ittNo, acntNo);
        ISTOMatching(_stoMatching).placeBuyOrder(orderId, acntAddress, tokenAddress, price, qty);
        emit BuyOrderPlaced(orderId, ittNo, acntNo, isuNo, price, qty, block.timestamp);
    }

    function placeSellOrder(uint256 orderId, bytes32 ittNo, bytes32 acntNo, bytes32 isuNo, uint256 price, uint256 qty) external virtual override {
        address tokenAddress = _checkIsuNo(isuNo);
        address acntAddress = _checkAcntNo(ittNo, acntNo);
        ISTOMatching(_stoMatching).placeSellOrder(orderId, acntAddress, tokenAddress, price, qty);
        emit SellOrderPlaced(orderId, ittNo, acntNo, isuNo, price, qty, block.timestamp);
    }

    function cancelBuyOrder(uint256 orderId) external virtual override {
        ISTOMatching(_stoMatching).cancelBuyOrder(orderId);
        emit BuyOrderCanceled(orderId, block.timestamp);
    }

    function cancelSellOrder(uint256 orderId) external virtual override {
        ISTOMatching(_stoMatching).cancelSellOrder(orderId);
        emit SellOrderCanceled(orderId, block.timestamp);
    }

    function replaceBuyOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external virtual override {
        ISTOMatching(_stoMatching).replaceBuyOrder(oldOrderId, newOrderId, price, qty);
        emit BuyOrderReplaced(oldOrderId, newOrderId, block.timestamp);
    }

    function replaceSellOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external virtual override {
        ISTOMatching(_stoMatching).replaceSellOrder(oldOrderId, newOrderId, price, qty);
        emit SellOrderReplaced(oldOrderId, newOrderId, block.timestamp);
    }

    function getOrder(uint256 orderId) external view virtual override returns (Order memory) {
        return ISTOMatching(_stoMatching).getOrder(orderId);
    }

    function getOrderBatch(uint256[] memory orderId) external view virtual override returns (Order[] memory) {
        return ISTOMatching(_stoMatching).getOrderBatch(orderId);
    }

    function getQuoteOrders(bytes32 isuNo, uint256 price) external view virtual override returns (Quote memory quote, Order[] memory) {
        address tokenAddress = _checkIsuNo(isuNo);
        return ISTOMatching(_stoMatching).getQuoteOrders(tokenAddress, price);
    }

    function getAllQuoteList(bytes32 isuNo) external view virtual override returns (Quote[] memory, Quote[] memory) {
        address tokenAddress = _checkIsuNo(isuNo);
        return ISTOMatching(_stoMatching).getAllQuoteList(tokenAddress);
    }

    function getOrderBook(bytes32 isuNo) external view virtual override returns (uint256[] memory) {
        address tokenAddress = _checkIsuNo(isuNo);
        return ISTOMatching(_stoMatching).getOrderBook(tokenAddress);
    }


    /** 기타 **/
    function getStoBeacon() external view returns (address) {
        return _stoBeacon;
    }

    function getStoMatching() external view returns (address) {
        return _stoMatching;
    }

    function getWhitelist() external view returns (address) {
        return _whitelist;
    }

    function getStoName(bytes32 isuNo) external view virtual returns (string memory) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        return SecurityTokenUpgradeable(_token[isuNo]).name();
    }

    function getStoSymbol(bytes32 isuNo) external view virtual returns (string memory) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        return SecurityTokenUpgradeable(_token[isuNo]).symbol();
    }

    function getStoAddress(bytes32 isuNo) external view virtual returns (address) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        return _token[isuNo];
    }


    function _checkIsuNo(bytes32 isuNo) internal view returns (address) {
        address tmpToken = _token[isuNo];

        if (tmpToken == address(0)) {
            revert ("isuNo not registered");
        }

        return tmpToken;
    }

    function _checkAcntNo(bytes32 ittNo, bytes32 acntNo) internal view returns (address) {
        (bool status, address acntAddress) = IWhitelist(_whitelist).getAccountAddress(ittNo, acntNo);

        if (!status) {
            revert ("ittNo, acntNo not registered");
        }

        return acntAddress;
    }
}