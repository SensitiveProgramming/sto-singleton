// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title MetaData Definition
/// @notice must constant only
contract MetaDataConstant {
    /// 잔고유형(BalTp)
    bytes32 public constant BalTp_00 = bytes32("00");
    bytes32 public constant BalTp_11 = bytes32("11");
    bytes32 public constant BalTp_12 = bytes32("12");
    bytes32 public constant BalTp_13 = bytes32("13");
    bytes32 public constant BalTp_14 = bytes32("14");
    bytes32 public constant BalTp_15 = bytes32("15");
    bytes32 public constant BalTp_21 = bytes32("21");
    bytes32 public constant BalTp_31 = bytes32("31");

    /// 입출고상세코드(IODtlCode)
    bytes32 public constant IODtlCode_11 = bytes32("11");
    bytes32 public constant IODtlCode_12 = bytes32("12");
    bytes32 public constant IODtlCode_21 = bytes32("21");
    bytes32 public constant IODtlCode_22 = bytes32("22");
    bytes32 public constant IODtlCode_31 = bytes32("31");
    bytes32 public constant IODtlCode_32 = bytes32("32");
    bytes32 public constant IODtlCode_41 = bytes32("41");
    bytes32 public constant IODtlCode_42 = bytes32("42");

    /// 거래사유코드(TxRsnCode)
    bytes32 public constant TxRsnCode_111 = bytes32("111");
    bytes32 public constant TxRsnCode_112 = bytes32("112");
    bytes32 public constant TxRsnCode_221 = bytes32("221");
    bytes32 public constant TxRsnCode_222 = bytes32("222");
    bytes32 public constant TxRsnCode_131 = bytes32("131");
    bytes32 public constant TxRsnCode_132 = bytes32("132");
    bytes32 public constant TxRsnCode_241 = bytes32("241");
    bytes32 public constant TxRsnCode_242 = bytes32("242");
    bytes32 public constant TxRsnCode_311 = bytes32("311");
    bytes32 public constant TxRsnCode_312 = bytes32("312");
    bytes32 public constant TxRsnCode_313 = bytes32("313");
    bytes32 public constant TxRsnCode_314 = bytes32("314");
    bytes32 public constant TxRsnCode_315 = bytes32("315");
    bytes32 public constant TxRsnCode_411 = bytes32("411");
    bytes32 public constant TxRsnCode_412 = bytes32("412");
    bytes32 public constant TxRsnCode_413 = bytes32("413");
    bytes32 public constant TxRsnCode_414 = bytes32("414");
    bytes32 public constant TxRsnCode_415 = bytes32("415");

    /// 종목상태코드(StatusCode)
    bytes32 public constant StatusCode_00 = bytes32("00");
    bytes32 public constant StatusCode_01 = bytes32("01");

    /// 계좌유형(AcntTp)
    bytes32 public constant AcntTp_01 = bytes32("01");
    bytes32 public constant AcntTp_02 = bytes32("02");
}