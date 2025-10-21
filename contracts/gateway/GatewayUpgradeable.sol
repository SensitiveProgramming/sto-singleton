// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IGateway} from "./IGateway.sol";
import {MetaDataConstant} from "./MetaDataConstant.sol";
import {STOUpgradeable} from "../proxy/utils/STOUpgradeable.sol";
import {DoublyLinkedList} from "../utils/structs/DoublyLinkedList.sol";

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
        // SecurityTokenUpgradeable(sto).initialize(string(abi.encodePacked(isuNo)), _whitelist);
        _token[isuNo] = sto;
        _exists[isuNo] = true;

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
    function accountQueryBalance(bytes32 ittNo, bytes32 acntNo) external virtual override returns (bytes32, bytes32, bytes32[] memory, bytes32[][] memory, uint256[][] memory, uint256[][] memory, bytes32[][] memory) {
        address acntAddress = _checkAcntNo(ittNo, acntNo);
        uint256 length = DoublyLinkedList.length(_acntTokens[ittNo][acntNo]);
        bytes32[] memory isuNo = new bytes32[](length);

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

    function accountQueryBalanceByIsuNo(bytes32 ittNo, bytes32 isuNo, bytes32 acntNo) external virtual override returns (bytes32, bytes32, bytes32, bytes32, bytes32[] memory, uint256[] memory, uint256[] memory, bytes32[] memory) {
        address tokenAddress = _checkIsuNo(isuNo);
        address acntAddress = _checkAcntNo(ittNo, acntNo);

        (bytes32[] memory balTp, uint256[] memory curr) = SecurityTokenUpgradeable(tokenAddress).allBalanceOf(acntAddress);

        uint256[] memory bf = curr;
        bytes32[] memory txid = new bytes32[](9);

        return (ittNo, acntNo, _acntTp[ittNo][acntNo], isuNo, balTp, curr, bf, txid);
    }

    // function accountQueryTransaction(bytes32 ittNo, bytes32 acntNo, txid) external virtual override returns ()


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

    // function upgradeStoLogic(address newImplementation) external {

    // }

    // function upgradeGatewayLogic(address newImplementation) external {
        
    // }

    // /// ERC20 (Fungible Token Standard) variables /////////////////////////////////////////////////////////////////////////////////////////
    // /// @dev 토큰 잔고
    // mapping (address => uint256) internal _balances;
    // /// @dev 토큰 전송 위임
    // mapping (address => mapping(address => uint256)) internal _allowances;
    // /// @dev 토큰 총량
    // uint256 internal _totalSupply;
    // /// @dev 토큰 명
    // string internal _name;
    // /// @dev 토큰 심볼
    // string internal _symbol;
    // /// @dev 토큰 데시멀
    // uint8 internal _decimals;
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



    // function tokenRegister(bytes32 isuNo) external virtual override {

    //     // _token[isuNo] = address(11);
    // }

    // function tokenQueryInfo(bytes32 isin) external virtual {
    //     _isuNo[isin];
    // }



    // /// Role //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // /// @dev KSD 권한
    // bytes32 public constant KSD_ROLE = keccak256("KSD_ROLE");
    // /// @dev 매니저 권한
    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // /// @dev 컨트롤러 권한
    // bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // /// ERC20 (Fungible Token Standard) variables /////////////////////////////////////////////////////////////////////////////////////////
    // /// @dev 토큰 잔고
    // mapping (address => uint256) internal _balances;
    // /// @dev 토큰 전송 위임
    // mapping (address => mapping(address => uint256)) internal _allowances;
    // /// @dev 토큰 총량
    // uint256 internal _totalSupply;
    // /// @dev 토큰 명
    // string internal _name;
    // /// @dev 토큰 심볼
    // string internal _symbol;
    // /// @dev 토큰 데시멀
    // uint8 internal _decimals;
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // /// ERC-1410 (Partially Fungible Token Standard) variables ////////////////////////////////////////////////////////////////////////////
    // /// @dev 모든 파티션 목록
    // bytes32[] internal _partitionList;
    // /// @dev 모든 파티션 인덱스
    // mapping (bytes32 => uint256) internal _indexAllPartitions;
    // /// @dev 지갑주소 파티션 목록
    // mapping (address => bytes32[]) internal _accountPartitions;
    // /// @dev 지갑주소 파티션 인덱스
    // mapping (address => mapping(bytes32 => uint256)) internal _indexAccountPartitions;
    // /// @dev 지갑주소 파티션 토큰 잔고
    // mapping (bytes32 => mapping(address => uint256)) internal _partitionBalances;
    // /// @dev 전체 파티션 토큰 전송 위임 여부
    // mapping (address => mapping(address => bool)) internal _allPartitionAllowances;
    // /// @dev 특정 파티션 토큰 전송 위임 여부
    // mapping (bytes32 => mapping(address => mapping(address => bool))) internal _partitionAllowances;
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // /// ERC-1594 (Core Security Token Standard) variables /////////////////////////////////////////////////////////////////////////////////
    // /// @dev 발행 가능 여부
    // bool internal _issuableStatus;
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // /// ERC-1643 (Document Management Standard) variables /////////////////////////////////////////////////////////////////////////////////
    // /// @dev 문서 uri
    // mapping (bytes32 => string) internal _documentUri;
    // /// @dev 문서 해시
    // mapping (bytes32 => bytes32) internal _documentHash;
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // /// ERC-1644 (Controller Token Operation Standard) variables //////////////////////////////////////////////////////////////////////////
    // uint256 internal _controllerNumOf;
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // /// SecurityToken extension variables /////////////////////////////////////////////////////////////////////////////////////////////////
    // /// @dev initial 파티션
    // /// @notice 100:처분가능, 201:질권, 202:압류
    // bytes32 public constant DISPOSABLE_PARTITION = bytes32("100");
    // bytes32 public constant PLEDGED_PARTITION = bytes32("201");
    // bytes32 public constant SEIZED_PARTITION = bytes32("202");
    // /// @dev 종목 소유자 목록 관리 구조체
    // DoublyLinkedList.AddressList internal _holderList;
    // /// @dev 종목 isin 코드
    // bytes32 internal _isin;
    // /// @dev 토큰 상태 유효 여부
    // bool internal _activeStatus;
    // /// @dev 거래 정지 여부
    // bool internal _pausedStatus;
    // /// @dev 화이트리스트 컨트랙트
    // Whitelist internal _whitelistContract;
    // /// @dev 642 계좌 별 수량 합계
    // mapping (bytes32 => uint256) internal _ksdAccountBalancesSum;
    // /// @dev (질권설정자 => 질권자) 수량 설정 정보
    // mapping (address => mapping(address => uint256)) internal _pledgedAmount;
    // /// @dev 처분제한 수량 합계: 총잔고수량 = 처분가능 + 질권 + 압류 + 처분제한수량합계(처분제한1 + 처분제한2 + ... + 처분제한n)
    // mapping (address => uint256) internal _totalRestrictedDisposalBalance;
    // /// @dev account의 642계좌
    // mapping (address => bytes32) _ksdAccount;
    // /// @dev 업무구분전표일련번호 총 발행 수량
    // mapping (bytes32 => uint256) internal _totalIssueAmount;
    // /// @dev 업무구분전표일련번호 총 말소 수량
    // mapping (bytes32 => uint256) internal _totalErasureAmount;
    // /// @dev 업무구분전표일련번호 발행 가능 수량
    // mapping (bytes32 => uint256) internal _totalIssuableCap;
    // /// @dev 업무구분전표일련번호 말소 가능 수량
    // mapping (bytes32 => uint256) internal _totalErasableCap;
    // /// @dev 업무구분전표일련번호 642계좌 발행 수량
    // mapping (bytes32 => mapping (bytes32 => uint256)) internal _ksdAccountIssueAmount;
    // /// @dev 업무구분전표일련번호 642계좌 말소 수량
    // mapping (bytes32 => mapping (bytes32 => uint256)) internal _ksdAccountErasureAmount;
    // /// @dev 업무구분전표일련번호 642계좌 발행 가능 수량
    // mapping (bytes32 => mapping (bytes32 => uint256)) internal _ksdAccountIssuableCap;
    // /// @dev 업무구분전표일련번호 642계좌 말소 가능 수량
    // mapping (bytes32 => mapping (bytes32 => uint256)) internal _ksdAccountErasableCap;
    // /// @dev 업무구분전표일련번호 발행 가능 642계좌 리스트
    // mapping (bytes32 => bytes32[]) internal _ksdAccountIssueList;
    // /// @dev 업무구분전표일련번호 말소 가능 642계좌 리스트
    // mapping (bytes32 => bytes32[]) internal _ksdAccountErasureList;
    // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}