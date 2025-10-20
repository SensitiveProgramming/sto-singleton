// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IWhitelist} from "./IWhitelist.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Whitelist 관리 컨트랙트
 * @notice 특정 고객/기관을 관리하기 위한 컨트랙트
 */
contract Whitelist is IWhitelist, AccessControl {
    /// Role //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @dev 예탁결제원 권한
    bytes32 public constant KSD_ROLE = keccak256("KSD_ROLE");
    /// @dev 계좌관리기관 권한
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /// Variables /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice 계좌관리기관 코드 (642중 6자리) => 계좌관리기관 대표지갑주소 (서명용)
    mapping (bytes32 => address) private _signAccount;
    /// @notice 계좌관리기관 대표지갑주소 (서명용) => 계좌관리기관 코드 (642중 6자리)
    mapping (address => bytes32) private _institutionCode;
    /// @notice 지갑주소 => 등록여부
    mapping(address => bool) private _status;
    /// @notice 지갑주소 => 642계좌
    mapping(address => bytes32) private _ksdAccount;
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(KSD_ROLE, msg.sender);
    }


    /// KSD_ROLE Functions ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function addInstitution(bytes32 acopNo, address signAccount) external virtual override onlyRole(KSD_ROLE) {
        if (_signAccount[acopNo] != address(0)) {
            revert InstitutionAlreadyRegistered(acopNo);
        }

        if (!_isValid(acopNo, 6)) {
            revert InvalidAcopNo(acopNo);
        }

        _signAccount[bytes32(bytes6(acopNo))] = signAccount;
        _institutionCode[signAccount] = bytes32(bytes6(acopNo));
        _grantRole(ADMIN_ROLE, signAccount);
        emit InstitutionAdded(bytes32(bytes6(acopNo)), signAccount);
    }

    function removeInstitution(bytes32 acopNo) external virtual override onlyRole(KSD_ROLE) {
        if (!_isValid(acopNo, 6)) {
            revert InvalidAcopNo(acopNo);
        }
        
        address signAccount = _signAccount[bytes32(bytes6(acopNo))];

        if (signAccount == address(0)) {
            revert InstitutionNotRegistered(bytes32(bytes6(acopNo)));
        }

        _signAccount[bytes32(bytes6(acopNo))] = address(0);
        _institutionCode[signAccount] = bytes32("");
        _revokeRole(ADMIN_ROLE, signAccount);
        emit InstitutionRemoved(bytes32(bytes6(acopNo)), signAccount);
    }

    function addSelfAccount(address selfAccount, bytes32 acopNo, bytes32 acopSeq, bytes32 accAcd) external virtual override onlyRole(KSD_ROLE) {
        if (_status[selfAccount]) {
            revert AccounAlreadyRegistered(selfAccount);
        }

        if (!_isValid(acopNo, 6)) {
            revert InvalidSelfAccountAcopNo(acopNo);
        }

        if (!_isValid(acopSeq, 4)) {
            revert InvalidSelfAccountAcopSeq(acopSeq);
        }

        if (!_isValid(accAcd, 2) || accAcd != bytes32("01")) {
            revert InvalidSelfAccountAccAcd(accAcd);
        }

        _status[selfAccount] = true;
        _ksdAccount[selfAccount] = bytes32(uint256(bytes32(bytes6(acopNo))) + uint256(bytes32(bytes4(acopSeq)) >> 48) + uint256(bytes32(bytes2(accAcd)) >> 80));
        emit SelfAccountAdded(selfAccount, _ksdAccount[selfAccount]);
    }

    function removeSelfAccount(address selfAccount) external virtual override onlyRole(KSD_ROLE) {
        if(!_status[selfAccount]) {
            revert AccounAlreadyRemoved(selfAccount);
        }

        emit SelfAccountRemoved(selfAccount, _ksdAccount[selfAccount]);
        _status[selfAccount] = false;
        _ksdAccount[selfAccount] = bytes32("");
    }

    function addUserAccount(address userAccount, bytes32 acopNo, bytes32 acopSeq, bytes32 accAcd) external virtual override onlyRole(KSD_ROLE) {
        if (_status[userAccount]) {
            revert AccounAlreadyRegistered(userAccount);
        }

        if (!_isValid(acopNo, 6)) {
            revert InvalidUserAccountAcopNo(acopNo);
        }

        if (!_isValid(acopSeq, 4)) {
            revert InvalidUserAccountAcopSeq(acopSeq);
        }

        if (!_isValid(accAcd, 2) || accAcd == bytes32("01")) {
            revert InvalidUserAccountAccAcd(accAcd);
        }

        _status[userAccount] = true;
        _ksdAccount[userAccount] = bytes32(uint256(bytes32(bytes6(acopNo))) + uint256(bytes32(bytes4(acopSeq)) >> 48) + uint256(bytes32(bytes2(accAcd)) >> 80));
        emit UserAccountAdded(msg.sender, userAccount, _ksdAccount[userAccount]);
    }

    function removeUserAccount(address userAccount) external virtual override onlyRole(KSD_ROLE) {
        if(!_status[userAccount]) {
            revert AccounAlreadyRemoved(userAccount);
        }

        emit UserAccountRemoved(msg.sender, userAccount, _ksdAccount[userAccount]);
        _status[userAccount] = false;
        _ksdAccount[userAccount] = bytes32("");
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /// ADMIN_ROLE Functions //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function addAccount(address account, bytes32 acopSeq, bytes32 accAcd) external virtual override onlyRole(ADMIN_ROLE) {
        bytes32 acopNo = _institutionCode[msg.sender];

        if (_status[account]) {
            revert AccounAlreadyRegistered(account);
        }

        if (acopNo == bytes32("")) {
            revert InstitutionNotRegistered(acopNo);
        }

        if (!_isValid(acopSeq, 4)) {
            revert InvalidUserAccountAcopSeq(acopSeq);
        }

        if (!_isValid(accAcd, 2) || bytes32(bytes2(accAcd)) == bytes32("01") ) {
            revert InvalidUserAccountAccAcd(accAcd);
        }

        _status[account] = true;
        _ksdAccount[account] = bytes32(uint256(acopNo) + uint256(bytes32(bytes4(acopSeq)) >> 48) + uint256(bytes32(bytes2(accAcd)) >> 80));
        emit UserAccountAdded(msg.sender, account, _ksdAccount[account]);
    }

    function removeAccount(address account) external virtual override onlyRole(ADMIN_ROLE) {
        if (!_status[account]) {
            revert AccounAlreadyRemoved(account);
        }

        if (bytes32(bytes6(_ksdAccount[account])) != _institutionCode[msg.sender]) {
            revert AnotherInstitutionUserAccount(account, bytes32(bytes6(_ksdAccount[account])));
        }

        emit UserAccountRemoved(msg.sender, account, _ksdAccount[account]);
        _status[account] = false;
        _ksdAccount[account] = bytes32("");
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /// Get Functions /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function getInstitutionSignAccount(bytes32 acopNo) external view virtual override returns (address) {
        return _signAccount[acopNo];
    }

    function getInstitutionCode(address signAccount) external view virtual override returns (bytes32) {
        return _institutionCode[signAccount];
    }

    function getAccount(address anyAccount) external view virtual override returns (bool, bytes32) {
        return (_status[anyAccount], _ksdAccount[anyAccount]);
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    function _isValid(bytes32 bytesString, uint256 length) internal pure returns (bool) {
        for (uint256 i=0; i<length; i++) {
            if (bytesString[i] == bytes1(0x00)) {
                return false;
            }
        }

        if (bytesString[length] != bytes1(0x00)) {
            return false;
        }

        return true;
    }
}