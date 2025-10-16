// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {DoublyLinkedList} from "../utils/structs/DoublyLinkedList.sol";
import {SortedLinkedList} from "../utils/structs/SortedLinkedList.sol";

/// @title 다자간상대매매 오더북 스토리지

/// @notice 매수/매도 구분
enum Side {
    Null,
    Buy,    // 매수
    Sell    // 매도
}

/// @notice 주문 상태
enum OrderStatus {
    Null,
    New,        // 신규 주문
    Partial,    // 부분 체결
    Filled,     // 전량 체결
    Canceled,   // 주문 취소
    Replaced,   // 주문 정정 (주문 취소 + 신규 주문)
    Rejected    // 주문 거절
}

/// @notice Maker/Taker 구분
enum LiquidityInd {
    Null,
    Maker,  // 유동성 공급
    Taker   // 유동성 감소
}

/// @notice 주문
/// @param orderId 주문 아이디
/// @param origClOrdId 주문 정정 시 이전 주문(취소) 아이디
/// @param account 사용자 지갑주소
/// @param side 매수/매도 구분
/// @param ordStatus 주문 상태 구분
/// @param token 토큰 컨트랙트 주소
/// @param price 주문 단가
/// @param orderQty 주문 수량 (orderQty = cumQty + leavesQty)
/// @param cumQty 누적 체결 수량
/// @param leavesQty 미체결 잔량 (주문 취소 시에는 미체결 수량만 취소)
/// @param tradeFee 거래 수수료
/// @param timestamp 주문 시각 (Unix timestamp)
struct Order {
    uint256 orderId;
    uint256 origClOrdId;
    address account;
    Side side;
    OrderStatus ordStatus;
    address token;
    uint256 price;
    uint256 orderQty;
    uint256 cumQty;
    uint256 leavesQty;
    uint256 tradeFee;
    uint256 timestamp;
}

/// @notice 호가창
/// @param side 매수/매도 구분
/// @param price 호가
/// @param orderCntAtPx 해당 호가 미체결 주문 건수
/// @param cumQtyAtPx 해당 호가 누적 체결 수량 합계
/// @param leavesQtyAtPx 해당 호가 미체결 잔량 합계
struct Quote {
    Side side;
    uint256 price;
    uint256 orderCntAtPx;
    uint256 cumQtyAtPx;
    uint256 leavesQtyAtPx;
}

/// @notice 오더북
/// @param quote 호가 정보 구조체
/// @param orderQueue 호가 미체결 주문 리스트
/// @param bidQuoteList 매수 호가 리스트
/// @param askQuoteList 매도 호가 리스트
/// @param quoteBidCnt 호가창 매수 주문 건수
/// @param quoteBidQty 호가창 매수 주문 건수
/// @param quoteBidNotional 호가창 매수 주문 대금 합계
/// @param quoteAskCnt 호가창 매도 주문 건수
/// @param quoteAskQty 호가창 매도 주문 건수
/// @param quoteAskNotional 호가창 매도 주문 대금 합계
/// @param tradeMinPrice 최저 체결 가격
/// @param tradeMaxPrice 최대 체결 가격
/// @param tradeLastPrice 마지막 체결 가격
/// @param tradeAvgPrice 체결 평균가
/// @param totalTradeQty 누적 체결 수량 합계
/// @param totalTradeNotional 누적 체결 대금 합계
struct OrderBook {
    uint256 quoteBidCnt;
    uint256 quoteBidQty;
    uint256 quoteBidNotional;
    uint256 quoteAskCnt;
    uint256 quoteAskQty;
    uint256 quoteAskNotional;
    uint256 tradeMinPrice;
    uint256 tradeMaxPrice;
    uint256 tradeLastPrice;
    uint256 tradeAvgPrice;
    uint256 totalTradeQty;
    uint256 totalTradeNotional;
    mapping (uint256 => Quote) quote;
    mapping (uint256 => DoublyLinkedList.Uint256List) orderQueue;
    SortedLinkedList.Uint256List bidQuoteList;
    SortedLinkedList.Uint256List askQuoteList;
    DoublyLinkedList.Uint256List tradeList;
    // AvlTree.Tree quoteTree;
}

/// @notice 수수료
/// @param feeRatio 수수료 비율
/// @param decimal 소수점
/// @param feeAccount 수수료 수신 지갑주소
/// @param round 소수점 이하 올림/내림 여부 (true: 올림, false: 내림)
/// 수수료 계산: (feeRatio: 15, decimal: 2 => 수수료: 15 * 10^-2 = 0.15%, 단위 %)
struct Fee {
    uint256 feeRatio;
    uint256 decimal;
    address feeAccount;
    bool round;
}

/// @notice 거래 정보
/// @param tradeId 거래 아이디
/// @param buyOrderId 매수 주문 아이디
/// @param buyInd 매수 주문 Maker/Taker 구분
/// @param sellOrderId 매도 주문 아이디
/// @param sellInd 매수 주문 Maker/Taker 구분
/// @param token 토큰 컨트랙트 주소
/// @param price 거래 단가
/// @param qty 거래 수량
/// @param notional 거래 대금
/// @param buyFee 매수 수수료
/// @param sellFee 매도 수수료
/// @param timestamp 거래 시각 (Unix timestamp)
struct Trade {
    uint256 tradeId;
    uint256 buyOrderId;
    LiquidityInd buyInd;
    uint256 sellOrderId;
    LiquidityInd sellInd;
    address token;
    uint256 price;
    uint256 qty;
    uint256 notional;
    uint256 buyFee;
    uint256 sellFee;
    uint256 timestamp;
}