// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {IGateway} from "./IGateway.sol";

import {CurrencyToken} from "../token/currency/CurrencyToken.sol";
import {STOMatching} from "../matching/STOMatching.sol";
import {STOBeacon} from "../proxy/beacon/STOBeacon.sol";
import {SecurityTokenUpgradeable} from "../token/security/SecurityTokenUpgradeable.sol";
import "../proxy/STOSelectableProxy.sol";

enum Meta {
    Null,
    /// 잔고유형(BalTp)
    BalTp_00,
    BalTp_11,
    BalTp_12,
    BalTp_13,
    BalTp_14,
    BalTp_15,
    BalTp_21,
    BalTp_31,

    /// 입출고상세코드(IODtlCode)
    IODtlCode_11,
    IODtlCode_12,
    IODtlCode_21,
    IODtlCode_22,
    IODtlCode_31,
    IODtlCode_32,
    IODtlCode_41,
    IODtlCode_42,

    /// 거래사유코드(TxRsnCode)
    TxRsnCode_111,
    TxRsnCode_112,
    TxRsnCode_221,
    TxRsnCode_222,
    TxRsnCode_131,
    TxRsnCode_132,
    TxRsnCode_241,
    TxRsnCode_242,
    TxRsnCode_311,
    TxRsnCode_312,
    TxRsnCode_313,
    TxRsnCode_314,
    TxRsnCode_315,
    TxRsnCode_411,
    TxRsnCode_412,
    TxRsnCode_413,
    TxRsnCode_414,
    TxRsnCode_415,

    /// 종목상태코드(StatusCode)
    StatusCode_00,
    StatusCode_01,

    /// 계좌유형(AcntTp)
    AcntTp_01,
    AcntTp_02
}

contract GatewayUpgradeable is Initializable, AccessControlUpgradeable, UUPSUpgradeable, IGateway {
    bytes32 private immutable VERSION;

    /// Role //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @dev 계좌관리기관 권한
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// Contract
    address internal _currencyToken;
    address internal _stoMatching;
    address internal _stoBeacon;
    // address internal _stoLogic;

    /// Meta data
    mapping (uint256 => bytes32) internal _meta;

    /// 종목관리
    mapping (bytes32 => address) internal _token;
    mapping (bytes32 => bool) internal _exists;
    mapping (bytes32 => bool) internal _ersYn;
    mapping (bytes32 => bytes32) internal _statusCode;

    constructor(string memory version) {
        _disableInitializers();
        VERSION = bytes32(abi.encodePacked(version));
    }

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());

        /// 잔고유형(BalTp)
        _meta[uint256(Meta.BalTp_00)] = bytes32(bytes("00"));
        _meta[uint256(Meta.BalTp_11)] = bytes32(bytes("11"));
        _meta[uint256(Meta.BalTp_12)] = bytes32(bytes("12"));
        _meta[uint256(Meta.BalTp_13)] = bytes32(bytes("13"));
        _meta[uint256(Meta.BalTp_14)] = bytes32(bytes("14"));
        _meta[uint256(Meta.BalTp_15)] = bytes32(bytes("15"));
        _meta[uint256(Meta.BalTp_21)] = bytes32(bytes("21"));
        _meta[uint256(Meta.BalTp_31)] = bytes32(bytes("31"));

        /// 입출고상세코드(IODtlCode)
        _meta[uint256(Meta.IODtlCode_11)] = bytes32(bytes("11"));
        _meta[uint256(Meta.IODtlCode_12)] = bytes32(bytes("12"));
        _meta[uint256(Meta.IODtlCode_21)] = bytes32(bytes("21"));
        _meta[uint256(Meta.IODtlCode_22)] = bytes32(bytes("22"));
        _meta[uint256(Meta.IODtlCode_31)] = bytes32(bytes("31"));
        _meta[uint256(Meta.IODtlCode_32)] = bytes32(bytes("32"));
        _meta[uint256(Meta.IODtlCode_41)] = bytes32(bytes("41"));
        _meta[uint256(Meta.IODtlCode_42)] = bytes32(bytes("42"));

        /// 거래사유코드(TxRsnCode)
        _meta[uint256(Meta.TxRsnCode_111)] = bytes32(bytes("111"));
        _meta[uint256(Meta.TxRsnCode_112)] = bytes32(bytes("112"));
        _meta[uint256(Meta.TxRsnCode_221)] = bytes32(bytes("221"));
        _meta[uint256(Meta.TxRsnCode_222)] = bytes32(bytes("222"));
        _meta[uint256(Meta.TxRsnCode_131)] = bytes32(bytes("131"));
        _meta[uint256(Meta.TxRsnCode_132)] = bytes32(bytes("132"));
        _meta[uint256(Meta.TxRsnCode_241)] = bytes32(bytes("241"));
        _meta[uint256(Meta.TxRsnCode_242)] = bytes32(bytes("242"));
        _meta[uint256(Meta.TxRsnCode_311)] = bytes32(bytes("311"));
        _meta[uint256(Meta.TxRsnCode_312)] = bytes32(bytes("312"));
        _meta[uint256(Meta.TxRsnCode_313)] = bytes32(bytes("313"));
        _meta[uint256(Meta.TxRsnCode_314)] = bytes32(bytes("314"));
        _meta[uint256(Meta.TxRsnCode_315)] = bytes32(bytes("315"));
        _meta[uint256(Meta.TxRsnCode_411)] = bytes32(bytes("411"));
        _meta[uint256(Meta.TxRsnCode_412)] = bytes32(bytes("412"));
        _meta[uint256(Meta.TxRsnCode_413)] = bytes32(bytes("413"));
        _meta[uint256(Meta.TxRsnCode_414)] = bytes32(bytes("414"));
        _meta[uint256(Meta.TxRsnCode_415)] = bytes32(bytes("415"));

        /// 종목상태코드(StatusCode)
        _meta[uint256(Meta.StatusCode_00)] = bytes32(bytes("00"));
        _meta[uint256(Meta.StatusCode_01)] = bytes32(bytes("01"));

        /// 계좌유형(AcntTp)
        _meta[uint256(Meta.AcntTp_01)] = bytes32(bytes("01"));
        _meta[uint256(Meta.AcntTp_02)] = bytes32(bytes("02"));

        _currencyToken = address(new CurrencyToken());
        _stoMatching = address(new STOMatching(_currencyToken));
        address stoLogic = address(new SecurityTokenUpgradeable("STO v1.0"));
        _stoBeacon = address(new STOBeacon(stoLogic, address(this), address(this)));
    }

    function getCurrencyToken() external view returns (address) {
        return _currencyToken;
    }

    function getStoMatching() external view returns (address) {
        return _stoMatching;
    }

    function getStoBeacon() external view returns (address) {
        return _stoBeacon;
    }

    function getStoLogic() external view returns (address) {
        return STOBeacon(_stoBeacon).implementation();
    }

    function getVersion() external view virtual returns (string memory) {
        return string(abi.encodePacked(VERSION));
    }

    function getImplementation() external view virtual returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function deployNewStoLogic(string memory version) external virtual returns (address) {
        address stoLogic = address(new SecurityTokenUpgradeable(version));
        STOBeacon(_stoBeacon).upgradeTo(stoLogic);
        return STOBeacon(_stoBeacon).implementation();
    }

    function tokenRegister(bytes32 isuNo) external virtual override returns (address) {
        if (_exists[isuNo]) {
            revert("isuNo already exists");
        }

        address sto = address(new STOSelectableProxy(true, _stoBeacon, address(0), ""));
        SecurityTokenUpgradeable(sto).initialize(string(abi.encodePacked(isuNo)), string(abi.encodePacked(isuNo)));
        _token[isuNo] = sto;
        _exists[isuNo] = true;
        return sto;
    }

    function tokenQueryInfo(bytes32 isuNo) external view returns (bytes32 isuNoOut, uint256 totalSupply, bool ersYn, bytes32 statusCode) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        address sto = _token[isuNo];
        return (isuNo, SecurityTokenUpgradeable(sto).totalSupply(), _ersYn[isuNo], _statusCode[isuNo]);
    }







    function getStoName(bytes32 isuNo) external view returns (string memory) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        return SecurityTokenUpgradeable(_token[isuNo]).name();
    }

    function getStoSymbol(bytes32 isuNo) external view returns (string memory) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        return SecurityTokenUpgradeable(_token[isuNo]).symbol();
    }

    function getStoAddress(bytes32 isuNo) external view returns (address) {
        if (!_exists[isuNo]) {
            revert("isuNo not exists");
        }

        return _token[isuNo];
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

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(ADMIN_ROLE) {}
}