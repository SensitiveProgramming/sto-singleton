// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IGateway {
    struct Transaction{
        bytes32 txid;
        bytes32 acntNo;
        bytes32 mgmtIttNo;
        bytes32 acntTp;
        bytes32 isuNo;
        bytes32 balTp;
        uint256 curr;
        uint256 bf;
        bytes32 desc;
        bytes32[20] _reserved;
    }

    // /** 사용자계좌등록 **/
    // /// 위탁계좌등록
    // function addAccount(bytes32 ittNo, bytes32 acntNo, address acntAddress) external;
    // /// 위탁계좌삭제
    // function removeAccount(bytes32 ittNo, bytes32 acntNo) external;
    // /// 자기계좌등록
    // function addSelfAccount(bytes32 ittNo, bytes32 acntNo, address acntAddress) external;
    // /// 위탁계좌삭제
    // function removeSelfAccount(bytes32 ittNo, bytes32 acntNo) external;
    // /// 계좌지갑주소조회
    // function getAccountAddress(bytes32 ittNo, bytes32 acntNo) external returns (bool status, address acntAddress);
    // /// 계좌조회
    // function getAddressInfo(address acntAddress) external returns (bool status, bytes32 ittNo, bytes32 acntNo);


    /** 종목관리 **/
    /// 종목등록
    function tokenRegister(bytes32 isuNo) external returns (address tokenAddress);
    /// 종목정보조회
    function tokenQueryInfo(bytes32 isuNo) external returns (bytes32 isuNoOut, uint256 totalSupply, bool ersYn, bytes32 statusCode);


    /** 증권관리 **/
    /// 입고
    function balanceStockIn(bytes32 ittNo, bytes32 acntNo, bytes32 acntTp, bytes32 trustYn, bytes32 isuNo, uint256 qty, bytes32 balTp, bytes32 iODtlCode, bytes32 trxCode, bytes32 desc) external;
    /// 출고
    function balanceStockOut(bytes32 ittNo, bytes32 acntNo, bytes32 acntTp, bytes32 trustYn, bytes32 isuNo, uint256 qty, bytes32 balTp, bytes32 iODtlCode, bytes32 trxCode, bytes32 desc) external;
    /// 자사대체
    function balanceTransfer(bytes32 ittNo, bytes32 fromAcntNo, bytes32 fromAcntTp, bytes32 fromTrustYn, bytes32 toAcntNo, bytes32 toAcntTp, bytes32 toTrustYn, bytes32 isuNo, uint256 qty, bytes32 desc) external;
    /// 타사대체
    function balanceTransferToItt(bytes32 fromittNo, bytes32 fromAcntNo, bytes32 fromAcntTp, bytes32 fromTrustYn, bytes32 toittNo, bytes32 toAcntNo, bytes32 toAcntTp, bytes32 toTrustYn, bytes32 isuNo, uint256 qty, bytes32 data, bytes32 desc) external;


    /** 계좌조회 **/
    /// 계좌잔고 조회
    function accountQueryBalance(bytes32 ittNo, bytes32 acntNo) external returns (bytes32 ittNoOut, bytes32 acntNoOut, bytes32[] memory isuNo, bytes32[][] memory balTp, uint256[][] memory curr, uint256[][] memory bf, bytes32[][] memory txid);
    /// 계좌 종목별 잔고 조회
    function accountQueryBalanceByIsuNo(bytes32 ittNo, bytes32 isuNo, bytes32 acntNo) external returns (bytes32 ittNoOut, bytes32 acntNoOut, bytes32 acntTp, bytes32 isuNoOut, bytes32[] memory balTp, uint256[] memory curr, uint256[] memory bf, bytes32[] memory txid);
    /// 거래내역 조회
    // function accountQueryTransaction(bytes32 ittNo, bytes32 acntNo, txid) external returns ()

    // event AccountQueryBalance(bytes32 ittNo, bytes32 acntNo, bytes32[] isuNo, bytes32[][] balTp, uint256[][] curr, uint256[][] bf);
    // event AccountQueryBalanceByIsuNo(
    //     bytes32 ittNo, 
    //     bytes32 acntNo,
    //     bytes32 acntNo, 
    // )

    event BalanceStockIn(bytes32 ittNo, bytes32 acntNo, bytes32 acntTp, bytes32 trustYn, bytes32 isuNo, uint256 qty, bytes32 balTp, bytes32 iODtlCode, bytes32 trxCode, bytes32 desc);
    event BalanceStockOut(bytes32 ittNo, bytes32 acntNo, bytes32 acntTp, bytes32 trustYn, bytes32 isuNo, uint256 qty, bytes32 balTp, bytes32 iODtlCode, bytes32 trxCode, bytes32 desc);
    event BalanceTransfer(bytes32 ittNo, bytes32 fromAcntNo, bytes32 fromAcntTp, bytes32 fromTrustYn, bytes32 toAcntNo, bytes32 toAcntTp, bytes32 toTrustYn, bytes32 isuNo, uint256 qty, bytes32 desc);
    event BalanceTransferToItt(bytes32 fromittNo, bytes32 fromAcntNo, bytes32 fromAcntTp, bytes32 fromTrustYn, bytes32 toittNo, bytes32 toAcntNo, bytes32 toAcntTp, bytes32 toTrustYn, bytes32 isuNo, uint256 qty, bytes32 data, bytes32 desc);
}