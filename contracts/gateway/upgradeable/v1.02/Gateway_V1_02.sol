// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../../../matching/STOMatchingStruct.sol";
import {ISTOMatching} from "../../../matching/ISTOMatching.sol";
import {Gateway_V1} from "../v1/Gateway_V1.sol";
import "hardhat/console.sol";

contract Gateway_V1_02 is Gateway_V1 {
    constructor(string memory version) Gateway_V1(version) {
    }

    function getOrderInfo(uint256 orderId) external view virtual returns (
            uint256 orderIdOut,
            uint256 origClOrdId,
            address account,
            uint256 side,
            uint256 ordStatus,
            address token,
            uint256 price,
            uint256 orderQty,
            uint256 cumQty,
            uint256 leavesQty,
            uint256 tradeFee,
            uint256 timestamp
    ) {
        Order memory order = ISTOMatching(_stoMatching).getOrder(orderId);

        orderIdOut = order.orderId;
        origClOrdId = order.origClOrdId;
        account = order.account;
        side = uint256(order.side);
        ordStatus = uint256(order.ordStatus);
        token = order.token;
        price = order.price;
        orderQty = order.orderQty;
        cumQty = order.cumQty;
        leavesQty = order.leavesQty;
        tradeFee = order.tradeFee;
        timestamp = order.timestamp;
    }

    function getOrderInfoBatch(uint256[] memory orderId) external view virtual returns (
            uint256[] memory orderIdOut,
            uint256[] memory origClOrdId,
            address[] memory account,
            uint256[] memory side,
            uint256[] memory ordStatus,
            address[] memory token,
            uint256[] memory price,
            uint256[] memory orderQty,
            uint256[] memory cumQty,
            uint256[] memory leavesQty,
            uint256[] memory tradeFee,
            uint256[] memory timestamp
    ) {
        Order[] memory orders = ISTOMatching(_stoMatching).getOrderBatch(orderId);
        uint256 length = orders.length;

        orderIdOut = new uint256[](length);
        origClOrdId = new uint256[](length);
        account = new address[](length);
        side = new uint256[](length);
        ordStatus = new uint256[](length);
        token = new address[](length);
        price = new uint256[](length);
        orderQty = new uint256[](length);
        cumQty = new uint256[](length);
        leavesQty = new uint256[](length);
        tradeFee = new uint256[](length);
        timestamp = new uint256[](length);

        for (uint256 i=0; i<length; i++) {
            orderIdOut[i] = orders[i].orderId;
            origClOrdId[i] = orders[i].origClOrdId;
            account[i] = orders[i].account;
            side[i] = uint256(orders[i].side);
            ordStatus[i] = uint256(orders[i].ordStatus);
            token[i] = orders[i].token;
            price[i] = orders[i].price ;
            orderQty[i] = orders[i].orderQty;
            cumQty[i] = orders[i].cumQty;
            leavesQty[i] = orders[i].leavesQty;
            tradeFee[i] = orders[i].tradeFee;
            timestamp[i] = orders[i].timestamp;
        }
    }

    function getQuoteOrdersInfo(bytes32 isuNo, uint256 priceIn) external view virtual returns (
        uint256 orderCntAtPx,
        uint256 cumQtyAtPx,
        uint256 leavesQtyAtPx,
        uint256[] memory orderId,
        uint256[] memory origClOrdId,
        address[] memory account,
        uint256[] memory side,
        uint256[] memory ordStatus,
        address[] memory token,
        uint256[] memory price,
        uint256[] memory orderQty,
        uint256[] memory cumQty,
        uint256[] memory leavesQty,
        uint256[] memory tradeFee,
        uint256[] memory timestamp
    ) {
        address tokenAddress = _checkIsuNo(isuNo);
        (Quote memory quote, Order[] memory orders) = ISTOMatching(_stoMatching).getQuoteOrders(tokenAddress, priceIn);
        uint256 length = orders.length;

        orderCntAtPx = quote.orderCntAtPx;
        cumQtyAtPx = quote.cumQtyAtPx;
        leavesQtyAtPx = quote.leavesQtyAtPx;

        orderId = new uint256[](length);
        origClOrdId = new uint256[](length);
        account = new address[](length);
        side = new uint256[](length);
        ordStatus = new uint256[](length);
        token = new address[](length);
        price = new uint256[](length);
        orderQty = new uint256[](length);
        cumQty = new uint256[](length);
        leavesQty = new uint256[](length);
        tradeFee = new uint256[](length);
        timestamp = new uint256[](length);

        for (uint256 i=0; i<length; i++) {
            orderId[i] = orders[i].orderId;
            origClOrdId[i] = orders[i].origClOrdId;
            account[i] = orders[i].account;
            side[i] = uint256(orders[i].side);
            ordStatus[i] = uint256(orders[i].ordStatus);
            token[i] = orders[i].token;
            price[i] = orders[i].price ;
            orderQty[i] = orders[i].orderQty;
            cumQty[i] = orders[i].cumQty;
            leavesQty[i] = orders[i].leavesQty;
            tradeFee[i] = orders[i].tradeFee;
            timestamp[i] = orders[i].timestamp;
        }
    }

    function getAllQuoteListInfo(bytes32 isuNo) external view virtual returns (
        uint256[] memory askPrice,
        uint256[] memory askOrderCntAtPx,
        uint256[] memory askCumQtyAtPx,
        uint256[] memory askLeavesQtyAtPx,
        uint256[] memory bidPrice,
        uint256[] memory bidOrderCntAtPx,
        uint256[] memory bidCumQtyAtPx,
        uint256[] memory bidLeavesQtyAtPx
    ) {
        address tokenAddress = _checkIsuNo(isuNo);
        (Quote[] memory askQuote, Quote[] memory bidQuote) = ISTOMatching(_stoMatching).getAllQuoteList(tokenAddress);
        uint256 askLength = askQuote.length;
        uint256 bidLength = bidQuote.length;
        console.log("askLength:", askLength);
        console.log("bidLength:", bidLength);

        askPrice = new uint256[](askLength);
        askOrderCntAtPx = new uint256[](askLength);
        askCumQtyAtPx = new uint256[](askLength);
        askLeavesQtyAtPx = new uint256[](askLength);
        for (uint256 i=0; i<askLength; i++) {
            askPrice[i] = askQuote[i].price;
            askOrderCntAtPx[i] = askQuote[i].orderCntAtPx;
            askCumQtyAtPx[i] = askQuote[i].cumQtyAtPx;
            askLeavesQtyAtPx[i] = askQuote[i].leavesQtyAtPx;
        }

        bidPrice = new uint256[](bidLength);
        bidOrderCntAtPx = new uint256[](bidLength);
        bidCumQtyAtPx = new uint256[](bidLength);
        bidLeavesQtyAtPx = new uint256[](bidLength);
        for (uint256 i=0; i<bidLength; i++) {
            bidPrice[i] = bidQuote[i].price;
            bidOrderCntAtPx[i] = bidQuote[i].orderCntAtPx;
            bidCumQtyAtPx[i] = bidQuote[i].cumQtyAtPx;
            bidLeavesQtyAtPx[i] = bidQuote[i].leavesQtyAtPx;
        }
    }

    function getOrderBookInfo(bytes32 isuNo) external view virtual returns (
        uint256 quoteBidCnt,
        uint256 quoteBidQty,
        uint256 quoteBidNotional,
        uint256 quoteAskCnt,
        uint256 quoteAskQty,
        uint256 quoteAskNotional,
        uint256 tradeMinPrice,
        uint256 tradeMaxPrice,
        uint256 tradeLastPrice,
        uint256 tradeAvgPrice,
        uint256 totalTradeQty,
        uint256 totalTradeNotional
    ) {
        address tokenAddress = _checkIsuNo(isuNo);
        uint256[] memory result = ISTOMatching(_stoMatching).getOrderBook(tokenAddress);

        quoteBidCnt = result[0];
        quoteBidQty = result[1];
        quoteBidNotional = result[2];
        quoteAskCnt = result[3];
        quoteAskQty = result[4];
        quoteAskNotional = result[5];
        tradeMinPrice = result[6];
        tradeMaxPrice = result[7];
        tradeLastPrice = result[8];
        tradeAvgPrice = result[9];
        totalTradeQty = result[10];
        totalTradeNotional = result[11];
    }
}