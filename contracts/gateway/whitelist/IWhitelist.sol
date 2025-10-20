// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Whitelist 컨트랙트 인터페이스
interface IWhitelist {
    /// KSD_ROLE Functions (예탁결제원) ////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice 계좌관리기관 등록
    /// @param acopNo 계좌관리기관 구분 코드 (642중 6)
    /// @param signAccount 계좌관리기관 대표지갑주소 (서명용)
    function addInstitution(bytes32 acopNo, address signAccount) external;

    /// @notice 계좌관리기관 삭제
    /// @param acopNo 계좌관리기관 구분 코드 (642중 6)
    function removeInstitution(bytes32 acopNo) external;

    /// @notice 자기분 지갑주소 등록
    /// @param selfAccount 계좌관리기관 자기분 지갑주소
    /// @param acopNo 642계좌 중 6
    /// @param acopSeq 642계좌 중 4
    /// @param accAcd 642계좌 중 2
    function addSelfAccount(address selfAccount, bytes32 acopNo, bytes32 acopSeq, bytes32 accAcd) external;

    /// @notice 자기분 지갑주소 삭제
    /// @param selfAccount 계좌관리기관 자기분 지갑주소
    function removeSelfAccount(address selfAccount) external;

    /// @notice 고객분 지갑주소 등록
    /// @param userAccount 고객분 지갑주소
    /// @param acopNo 642계좌 중 6
    /// @param acopSeq 642계좌 중 4
    /// @param accAcd 642계좌 중 2
    function addUserAccount(address userAccount, bytes32 acopNo, bytes32 acopSeq, bytes32 accAcd) external;

    /// @notice 고객분 지갑주소 삭제
    /// @param userAccount 고객분 지갑주소
    function removeUserAccount(address userAccount) external;
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /// ADMIN_ROLE Functions (계좌관리기관) ////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice 고객분 지갑주소 등록
    /// @param account 고객분 지갑주소
    /// @param acopSeq 642계좌 중 4
    /// @param accAcd 642계좌 중 2
    function addAccount(address account, bytes32 acopSeq, bytes32 accAcd) external;

    /// @notice 고객분 지갑주소 삭제
    /// @param account 고객분 지갑주소
    function removeAccount(address account) external;
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /// Get Functions /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice 계좌관리기관 대표지갑주소 조회
    /// @param acopNo 계좌관리기관 구분 코드 (642중 6)
    /// @return signAccount 계좌관리기관 대표지갑주소 (서명용)
    function getInstitutionSignAccount(bytes32 acopNo) external returns (address signAccount);

    /// @notice 계좌관리기관 구분코드 조회
    /// @param signAccount 계좌관리기관 대표지갑주소
    /// @return acopNo 계좌관리기관 구분 코드 (642중 6)
    function getInstitutionCode(address signAccount) external returns (bytes32 acopNo);

    /// @notice 지갑주소 화이트리스트 등록 정보 조회
    /// @param anyAccount 지갑주소 (자기분/고객분)
    /// @return status 화이트리스트 등록여보 (true/false)
    /// @return ksdAccount 642계좌
    function getAccount(address anyAccount) external returns (bool status, bytes32 ksdAccount);
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /// Events ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice 계좌관리기관 등록 이벤트
    /// @param acopNo 계좌관리기관 구분 코드 (642중 6)
    /// @param signAccount 계좌관리기관 대표지갑주소 (서명용)
    event InstitutionAdded(bytes32 acopNo, address signAccount);

    /// @notice 계좌관리기관 삭제 이벤트
    /// @param acopNo 계좌관리기관 구분 코드 (642중 6)
    /// @param signAccount 계좌관리기관 대표지갑주소 (서명용)
    event InstitutionRemoved(bytes32 acopNo, address signAccount);

    /// @notice 자기분 지갑주소 등록 이벤트
    /// @param selfAccount 계좌관리기관 자기분 지갑주소
    /// @param ksdAccount 642계좌
    event SelfAccountAdded(address selfAccount, bytes32 ksdAccount);

    /// @notice 자기분 지갑주소 삭제 이벤트
    /// @param selfAccount 계좌관리기관 자기분 지갑주소
    /// @param ksdAccount 642계좌
    event SelfAccountRemoved(address selfAccount, bytes32 ksdAccount);

    /// @notice 고객분 지갑주소 등록 이벤트
    /// @param operator 오퍼레이터 지갑주소
    /// @param userAccount 고객분 지갑주소
    /// @param ksdAccount 642계좌
    event UserAccountAdded(address operator, address userAccount, bytes32 ksdAccount);

    /// @notice 고객분 지갑주소 삭제 이벤트
    /// @param operator 오퍼레이터 지갑주소
    /// @param userAccount 고객분 지갑주소
    /// @param ksdAccount 642계좌
    event UserAccountRemoved(address operator, address userAccount, bytes32 ksdAccount);
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /// Errors ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice 이미 등록되어 있는 계좌관리기관
    error InstitutionAlreadyRegistered(bytes32 acopNo);
    /// @notice 등록되지 않은 계좌관리기관
    error InstitutionNotRegistered(bytes32 acopNo);
    /// @notice 등록되지 않은 계좌관리기관 대표지갑주소
    error SignAccountNotRegistered(address signAccount);
    /// @notice 화이트리스트에 이미 등록되어 있는 지갑주소
    error AccounAlreadyRegistered(address account);
    /// @notice 화이트리스트에서 이미 삭제된 지갑주소
    error AccounAlreadyRemoved(address account);
    /// @notice 다른 기관이 등록한 고객 지갑주소
    error AnotherInstitutionUserAccount(address account, bytes32 registerAcopNo);
    /// @notice 기관구분코드 입력 오류
    error InvalidAcopNo(bytes32 acopNo);
    /// @notice 자기분 지갑주소 642계좌 입력 오류 (6)
    error InvalidSelfAccountAcopNo(bytes32 acopNo);
    /// @notice 자기분 지갑주소 642계좌 입력 오류 (4)
    error InvalidSelfAccountAcopSeq(bytes32 acopSeq);
    /// @notice 자기분 지갑주소 642계좌 입력 오류 (2)
    error InvalidSelfAccountAccAcd(bytes32 accAcd);
    /// @notice 고객분 지갑주소 642계좌 입력 오류 (6)
    error InvalidUserAccountAcopNo(bytes32 acopNo);
    /// @notice 고객분 지갑주소 642계좌 입력 오류 (4)
    error InvalidUserAccountAcopSeq(bytes32 acopSeq);
    /// @notice 고객분 지갑주소 642계좌 입력 오류 (2)
    error InvalidUserAccountAccAcd(bytes32 accAcd);
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}