// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title 다자간상대매매 오더북 인터페이스

import "./STOMatchingStruct.sol";

interface ISTOMatching {
    function placeBuyOrder(uint256 orderId, address account, address token, uint256 price, uint256 qty) external returns (bool placed);
    function placeSellOrder(uint256 orderId, address account, address token, uint256 price, uint256 qty) external returns (bool placed);
    function cancelBuyOrder(uint256 orderId) external returns (bool canceled);
    function cancelSellOrder(uint256 orderId) external returns (bool canceled);
    function replaceBuyOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external returns (bool replaced);
    function replaceSellOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external returns (bool replaced);

    function setBuyFee(uint256 feeRatio, uint256 decimal, address feeAccount, bool round) external;
    function setSellFee(uint256 feeRatio, uint256 decimal, address feeAccount, bool round) external;

    function getOrder(uint256 orderId) external view returns (Order memory order);
    function getOrderBatch(uint256[] memory orderId) external view returns (Order[] memory order);
    function getQuoteOrders(address token, uint256 price) external view returns (Quote memory quote, Order[] memory orders);
    function getAllQuoteList(address token) external view returns (Quote[] memory askQuoteList, Quote[] memory bidQuoteList);
    function getOrderBook(address token) external view returns (uint256[] memory orderBookInfo);

    // function getOrder(uint256 orderId) external view returns (Order memory order);
    // function getBidQuote(address token) external view returns (uint256[] memory price, uint256[] memory orderCntAtPx, uint256[] memory cumQtyAtPx, uint256[] memory leavesQtyAtPx);
    // function getAskQuote(address token) external view returns (uint256[] memory price, uint256[] memory orderCntAtPx, uint256[] memory cumQtyAtPx, uint256[] memory leavesQtyAtPx);
    // function getAllQuote(address token) external view returns (Quote[] memory askQuoteList, Quote[] memory bidQuoteList);
    // function getQuoteOrders(address token, uint256 price) external view returns (Quote memory quote, Order[] memory orders);

    // function getOrdersAtPrice(address token, uint256 price) external view returns (
    //     Side side, 
    //     uint256 orderQtyAtPx, 
    //     uint256 cumQtyAtPx, 
    //     uint256 leavesQtyAtPx, 
    //     uint256 headOrdId, 
    //     uint256 tailOrdId, 
    //     uint256 ordLength, 
    //     Order[] memory orders);

    // function getOrderBook(address token) external view returns (
    //     uint256 quoteBidCnt,
    //     uint256 quoteBidQty,
    //     uint256 quoteBidNotional,
    //     uint256 quoteAskCnt,
    //     uint256 quoteAskQty,
    //     uint256 quoteAskNotional,
    //     uint256 bestBidPrice,
    //     uint256 bestAskPrice,
    //     // uint256 quoteMinBid,
    //     // uint256 quoteMaxBid,
    //     // uint256 quoteMinAsk,
    //     // uint256 quoteMaxAsk,
    //     uint256 tradeMinPrice,
    //     uint256 tradeMaxPrice,
    //     uint256 tradeLastPrice,
    //     uint256 tradeAvgPrice,
    //     uint256 totalTradeQty,
    //     uint256 totalTradeNotional
    // );

    // function getOrderBookInfo(address token) external view returns (OrderBook book);
    // function getQuoteRange(address token, Price startPrice, )
    // // // function getLastPrice(address token) external view returns (uint256);
    // // // function getPendingOrderInfo(address token, uint256 unitPrice) external view returns (OrderType orderType, uint256 pendingOrders, uint256 pendingAmount);
    // 주문 (액션)
    //     매수 주문 제출	placeBuyOrder()		사용자가 매수 주문을 생성 (Buy)
    //     매도 주문 제출   placeSellOrder()	사용자가 매도 주문을 생성 (Sell)
    //     주문 취소        cancelOrder()		특정 주문 ID를 취소
    //     여러 주문 취소	cancelAllOrders()	사용자 계정의 모든 주문 취소

    // 호가창 (상태)
    //     최우선 매수호가	getBestBid()		오더북의 가장 높은 매수호가
    //     최우선 매도호가	getBestAsk()		오더북의 가장 낮은 매도호가
    //     특정 가격 매수 잔량	getBidVolume(price)	가격대별 매수 총 잔량
    //     특정 가격 매도 잔량	getAskVolume(price)	가격대별 매도 총 잔량
    //     전체 매수호가 리스트	getBidOrders()		오더북의 매수 주문 리스트
    //     전체 매도호가 리스트	getAskOrders()		오더북의 매도 주문 리스트

    // 체결/통계
    //     마지막 체결 가격	getLastTradePrice()	최근 체결된 가격 (LastPx)
    //     체결 이력		getTradeHistory()	거래 내역 조회
    //     누적 거래량	getCumulativeVolume()	기간 내 총 체결 수량
    //     누적 거래대금	getCumulativeNotional()	기간 내 총 체결 금액

    event BuyOrderPlaced(uint256 indexed orderId, address indexed account, address indexed token, uint256 price, uint256 qty, uint256 tradeFee, uint256 timestamp);
    event SellOrderPlaced(uint256 indexed orderId, address indexed account, address indexed token, uint256 price, uint256 qty, uint256 tradeFee, uint256 timestamp);
    event BuyOrderCanceled(uint256 indexed orderId, uint256 timestamp);
    event SellOrderCanceled(uint256 indexed orderId, uint256 timestamp);
    event BuyOrderReplaced(uint256 indexed oldOrderId, uint256 indexed newOrderId, uint256 timestamp);
    event SellOrderReplaced(uint256 indexed oldOrderId, uint256 indexed newOrderId, uint256 timestamp);
    event OrderMatched(uint256 tradeId, uint256 buyOrderId, LiquidityInd buyInd, uint256 sellOrderId, LiquidityInd sellInd, address token, uint256 price, uint256 qty, uint256 notional, uint256 buyFee, uint256 sellFee, uint256 timestamp);

    error DuplicateOrderId(uint256 orderId);
    error ZeroAddressToken();
    error ZeroAddressAccount();
    error ZeroOrderPrice();
    error ZeroOrderQuantity();
    error OrderIdNotFound(uint256 orderId);
    error OrderSideMismatch(uint256 orderId, Side side);
    error UncancellableOrderStatus(uint256 orderId, OrderStatus status);
    error OrderExceedingRemainingQuantity(uint256 oldOrderId, uint256 oldLeavesQty, uint256 newOrderQty);
}