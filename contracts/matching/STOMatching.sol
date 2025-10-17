// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title 다자간상대매매 매칭엔진 컨트랙트

import "./STOMatchingStruct.sol";
import {ISTOMatching} from "./ISTOMatching.sol";
import {IERC20Lock} from "../token/extension/IERC20Lock.sol";

contract STOMatching is ISTOMatching {
    /// 주문 아이디 (global unique) => 주문 구조체
    mapping (uint256 => Order) internal _order;
    /// 증권토큰 컨트랙트 주소 => 오더북 구조체
    mapping (address => OrderBook) internal _book;
    /// 거래 아이디 (global unique)
    uint256 internal _tradeId;
    /// 거래 정보
    mapping (uint256 => Trade) internal _tradeInfo;
    /// 결제 토큰 컨트랙트
    address internal _currencyToken;
    /// 매수 거래 수수료
    Fee internal _buyFee;
    /// 매도 거래 수수료
    Fee internal _sellFee;

    constructor(address currencyToken) {
        _currencyToken = currencyToken;
        setBuyFee(0, 1, msg.sender, true);
        setSellFee(0, 1, msg.sender, false);
    }

    function placeBuyOrder(uint256 orderId, address account, address token, uint256 price, uint256 qty) external virtual returns (bool) {
        return _placeOrder(orderId, 0, account, token, price, qty, Side.Buy);
    }

    function placeSellOrder(uint256 orderId, address account, address token, uint256 price, uint256 qty) external virtual returns (bool) {
        return _placeOrder(orderId, 0, account, token, price, qty, Side.Sell);
    }

    function cancelBuyOrder(uint256 orderId) external virtual returns (bool) {
        return _cancleOrder(orderId, Side.Buy);
    }

    function cancelSellOrder(uint256 orderId) external virtual returns (bool) {
        return _cancleOrder(orderId, Side.Sell);
    }

    function replaceBuyOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external virtual returns (bool) {
        return _replaceOrder(oldOrderId, newOrderId, price, qty, Side.Buy);
    }

    function replaceSellOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external virtual returns (bool) {
        return _replaceOrder(oldOrderId, newOrderId, price, qty, Side.Sell);
    }

    function setBuyFee(uint256 feeRatio, uint256 decimal, address feeAccount, bool round) public virtual {
        _buyFee = Fee({
            feeRatio: feeRatio,
            decimal: decimal,
            feeAccount: feeAccount,
            round: round
        });
    }

    function setSellFee(uint256 feeRatio, uint256 decimal, address feeAccount, bool round) public virtual {
        _sellFee = Fee({
            feeRatio: feeRatio,
            decimal: decimal,
            feeAccount: feeAccount,
            round: round
        });
    }

    function getOrder(uint256 orderId) external view virtual returns (Order memory) {
        return _order[orderId];
    }

    function getOrderBatch(uint256[] memory orderId) external view virtual returns (Order[] memory) {
        uint256 length = orderId.length;
        Order[] memory order = new Order[](length);

        for (uint256 i=0; i<length; i++) {
            order[i] = _order[orderId[i]];
        }

        return order;
    }

    function getQuoteOrders(address token, uint256 price) external view virtual returns (Quote memory, Order[] memory) {
        uint256 length = DoublyLinkedList.length(_book[token].orderQueue[price]);
        Order[] memory order = new Order[](length);
        uint256 tmpOrdId = _book[token].orderQueue[price].head;

        for (uint256 i=0; i<length; i++) {
            order[i] = _order[tmpOrdId];
            tmpOrdId = _book[token].orderQueue[price].next[tmpOrdId];
        }

        return (_book[token].quote[price], order);
    }

    function getAllQuoteList(address token) external view virtual returns (Quote[] memory, Quote[] memory) {
        uint256 asklength = SortedLinkedList.length(_book[token].askQuoteList);
        uint256 bidlength = SortedLinkedList.length(_book[token].bidQuoteList);
        Quote[] memory askQuoteList = new Quote[](asklength);
        Quote[] memory bidQuoteList = new Quote[](bidlength);

        uint256 tmpPrice = _book[token].askQuoteList.tail;
        for (uint256 i=0; i<asklength; i++) {
            askQuoteList[i] = _book[token].quote[tmpPrice];
            tmpPrice = _book[token].askQuoteList.prev[tmpPrice];
        }

        tmpPrice = _book[token].bidQuoteList.tail;
        for (uint256 i=0; i<bidlength; i++) {
            bidQuoteList[i] = _book[token].quote[tmpPrice];
            tmpPrice = _book[token].bidQuoteList.prev[tmpPrice];
        }

        return (askQuoteList, bidQuoteList);
    }

    function getOrderBook(address token) external view virtual returns (uint256[] memory) {
        uint256[] memory orderBookInfo = new uint256[](16);

        orderBookInfo[0] = _book[token].quoteBidCnt;
        orderBookInfo[1] = _book[token].quoteBidQty;
        orderBookInfo[2] = _book[token].quoteBidNotional;
        orderBookInfo[3] = _book[token].quoteAskCnt;
        orderBookInfo[4] = _book[token].quoteAskQty;
        orderBookInfo[5] = _book[token].quoteAskNotional;
        orderBookInfo[6] = _book[token].bidQuoteList.head;
        orderBookInfo[7] = _book[token].bidQuoteList.tail;
        orderBookInfo[8] = _book[token].askQuoteList.head;
        orderBookInfo[9] = _book[token].askQuoteList.tail;
        orderBookInfo[10] = _book[token].tradeMinPrice;
        orderBookInfo[11] = _book[token].tradeMaxPrice;
        orderBookInfo[12] = _book[token].tradeLastPrice;
        orderBookInfo[13] = _book[token].tradeAvgPrice;
        orderBookInfo[14] = _book[token].totalTradeQty;
        orderBookInfo[15] = _book[token].totalTradeNotional;

        return orderBookInfo;
    }

    function _placeOrder(uint256 orderId, uint256 oldOrderId, address account, address token, uint256 price, uint256 qty, Side side) private returns (bool) {
        if (token == address(0)) {
            revert ZeroAddressToken();
        } else if (account == address(0)) {
            revert ZeroAddressAccount();
        } else if (price == 0) {
            revert ZeroOrderPrice();
        } else if (qty == 0) {
            revert ZeroOrderQuantity();
        } else if (_order[orderId].orderId != 0) {
            revert DuplicateOrderId(orderId);
        }

        uint256 tradeFee;

        if (side == Side.Buy) {
            tradeFee = _getFee(price * qty, _buyFee);
        } else if (side == Side.Sell) {
            tradeFee = _getFee(price * qty, _sellFee);
        }

        _order[orderId] = Order({
            orderId: orderId,
            origClOrdId: oldOrderId,
            account: account,
            side: side,
            ordStatus: OrderStatus.New,
            token: token,
            price: price,
            orderQty: qty,
            cumQty: 0,
            leavesQty: qty,
            tradeFee: tradeFee,
            timestamp: block.timestamp
        });

        Side oldSide = _book[token].quote[price].side;

        if (oldSide == Side.Null) {
            if (side == Side.Buy) {
                IERC20Lock(_currencyToken).lock(account, qty * price + tradeFee);
                _book[token].quoteBidCnt++;
                _book[token].quoteBidQty += qty;
                _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qty;
                SortedLinkedList.insertSortedDsc(_book[token].bidQuoteList, price);
                emit BuyOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
            } else if (side == Side.Sell) {
                IERC20Lock(token).lock(account, qty);
                _book[token].quoteAskCnt++;
                _book[token].quoteAskQty += qty;
                _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qty;
                SortedLinkedList.insertSortedAsc(_book[token].askQuoteList, price);
                emit SellOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
            }

            _book[token].quote[price].side = side;
            _book[token].quote[price].price = price;
            _book[token].quote[price].orderCntAtPx++;
            _book[token].quote[price].leavesQtyAtPx += qty;
            DoublyLinkedList.insert(_book[token].orderQueue[price], orderId);
        } else if (oldSide == side) {
            if (side == Side.Buy) {
                IERC20Lock(_currencyToken).lock(account, qty * price + tradeFee);
                _book[token].quoteBidCnt++;
                _book[token].quoteBidQty += qty;
                _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qty;
                emit BuyOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
            } else if (side == Side.Sell) {
                IERC20Lock(token).lock(account, qty);
                _book[token].quoteAskCnt++;
                _book[token].quoteAskQty += qty;
                _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qty;
                emit SellOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
            }

            _book[token].quote[price].orderCntAtPx++;
            _book[token].quote[price].leavesQtyAtPx += qty;
            DoublyLinkedList.insert(_book[token].orderQueue[price], orderId);
        } else {
            if (side == Side.Buy) {
                IERC20Lock(_currencyToken).lock(account, qty * price + tradeFee);
                emit BuyOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
                // _book[token].quoteBidCnt++;
                // _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qty;
            } else if (side == Side.Sell) {
                IERC20Lock(token).lock(account, qty);
                emit SellOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
                // _book[token].quoteAskCnt++;
                // _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qty;
            }

            uint256 qtyRemain = qty;
            uint256 tmpOrdId = _book[token].orderQueue[price].head;

            while (tmpOrdId != 0) {
                if (_order[tmpOrdId].leavesQty > qtyRemain) {
                    /// @dev TODO: implements `_trade` logic
                    _trade(tmpOrdId, orderId, token, price, qtyRemain);

                    /// @dev 매칭에 의한 오더북(OrderBook) 정보 변경
                    if (side == Side.Buy) {
                        _book[token].quoteAskQty -= qtyRemain;
                        _book[token].quoteAskNotional = _book[token].quoteAskNotional - price * qtyRemain;
                    } else if (side == Side.Sell) {
                        _book[token].quoteBidQty -= qtyRemain;
                        _book[token].quoteBidNotional = _book[token].quoteBidNotional - price * qtyRemain;
                    }

                    /// @dev 매칭에 의한 호가창(Quote) 정보 변경
                    _book[token].quote[price].cumQtyAtPx += qtyRemain;
                    _book[token].quote[price].leavesQtyAtPx -= qtyRemain;

                    /// @dev 매칭에 의한 기존 주문(Order) 정보 변경
                    _order[tmpOrdId].ordStatus = OrderStatus.Partial;
                    _order[tmpOrdId].cumQty += qtyRemain;
                    _order[tmpOrdId].leavesQty -= qtyRemain;

                    /// @dev 주문 전량 처리 완료
                    qtyRemain = 0;
                    break;
                } else {
                    /// @dev TODO: implements `_trade` logic
                    _trade(tmpOrdId, orderId, token, price, _order[tmpOrdId].leavesQty);

                    /// @dev 남은 주문 수량 처리
                    qtyRemain -= _order[tmpOrdId].leavesQty;

                    /// @dev 매칭에 의한 오더북(OrderBook) 정보 변경
                    if (side == Side.Buy) {
                        _book[token].quoteAskCnt--;
                        _book[token].quoteAskQty -= _order[tmpOrdId].leavesQty;
                        _book[token].quoteAskNotional = _book[token].quoteAskNotional - price * _order[tmpOrdId].leavesQty;
                    } else if (side == Side.Sell) {
                        _book[token].quoteBidCnt--;
                        _book[token].quoteBidQty -= _order[tmpOrdId].leavesQty;
                        _book[token].quoteBidNotional = _book[token].quoteBidNotional - price * _order[tmpOrdId].leavesQty;
                    }

                    /// @dev 매칭에 의한 호가창(Quote) 정보 변경
                    _book[token].quote[price].orderCntAtPx--;
                    _book[token].quote[price].cumQtyAtPx += _order[tmpOrdId].leavesQty;
                    _book[token].quote[price].leavesQtyAtPx -= _order[tmpOrdId].leavesQty;

                    /// @dev 매칭에 의한 기존 주문(Order) 정보 변경
                    _order[tmpOrdId].ordStatus = OrderStatus.Filled;
                    _order[tmpOrdId].cumQty = _order[tmpOrdId].orderQty;
                    _order[tmpOrdId].leavesQty = 0;
                }

                uint256 beforeTmpOrdId = tmpOrdId;
                tmpOrdId = _book[token].orderQueue[price].next[tmpOrdId];
                DoublyLinkedList.remove(_book[token].orderQueue[price], beforeTmpOrdId);
            }

            if (qtyRemain > 0) {
                /// @dev 매칭 후 잔량에 의한 오더북(OrderBook) 정보 변경
                if (side == Side.Buy) {
                    _book[token].quoteBidCnt++;
                    _book[token].quoteBidQty += qtyRemain;
                    _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qtyRemain;
                    SortedLinkedList.remove(_book[token].askQuoteList, price);
                    SortedLinkedList.insertSortedDsc(_book[token].bidQuoteList, price);
                } else if (side == Side.Sell) {
                    _book[token].quoteAskCnt++;
                    _book[token].quoteAskQty += qtyRemain;
                    _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qtyRemain;
                    SortedLinkedList.remove(_book[token].bidQuoteList, price);
                    SortedLinkedList.insertSortedAsc(_book[token].askQuoteList, price);
                }

                /// @dev 주문 수량이 호가창 잔량보다 많아 매칭 후 신규(side 반대) 주문 호가창 추가
                _book[token].quote[price].side = side;
                _book[token].quote[price].orderCntAtPx = 1;
                _book[token].quote[price].leavesQtyAtPx = qtyRemain;
                DoublyLinkedList.insert(_book[token].orderQueue[price], orderId);

                /// @dev 주문(Order) 정보 수정
                _order[orderId].cumQty = _order[orderId].orderQty - qtyRemain;
                _order[orderId].leavesQty = qtyRemain;
                _order[orderId].ordStatus = OrderStatus.Partial;
            } else {
                /// @dev 주문(Order) 정보 수정
                _order[orderId].cumQty = _order[orderId].orderQty;
                _order[orderId].leavesQty = 0;
                _order[orderId].ordStatus = OrderStatus.Filled;
            }

            if (_book[token].quote[price].orderCntAtPx == 0) {
                /// @dev 주문 수량과 호가창 잔량이 정확히 일치하여 해당 호가창 삭제
                _book[token].quote[price].side = Side.Null;

                /// @dev TODO: 해당 호가창 리스트에서 삭제하는 로직 구현
                if (SortedLinkedList.exists(_book[token].askQuoteList, price)) {
                    SortedLinkedList.remove(_book[token].askQuoteList, price);
                }

                if (SortedLinkedList.exists(_book[token].bidQuoteList, price)) {
                    SortedLinkedList.remove(_book[token].bidQuoteList, price);
                }
            }

            if (price < _book[token].tradeMinPrice || _book[token].tradeMinPrice == 0) {
                _book[token].tradeMinPrice = price;
            }

            if (price > _book[token].tradeMaxPrice || _book[token].tradeMaxPrice == 0) {
                _book[token].tradeMaxPrice = price;
            }

            /// @dev TODO: implements trade result
            uint256 qtyTrade = qty - qtyRemain;
            _book[token].tradeLastPrice = price;
            _book[token].tradeAvgPrice = (_book[token].totalTradeNotional + price * qtyTrade) / (_book[token].totalTradeQty + qtyTrade);
            _book[token].totalTradeQty += qtyTrade;
            _book[token].totalTradeNotional = _book[token].totalTradeNotional + price * qtyTrade;
        }

        return true;
    }

    function _cancleOrder(uint256 orderId, Side side) private returns (bool) {
        address token = _order[orderId].token;
        uint256 price = _order[orderId].price;
        uint256 leavesQty = _order[orderId].leavesQty;
        OrderStatus orderStatus = _order[orderId].ordStatus;

        if (_order[orderId].account == address(0)) {
            revert OrderIdNotFound(orderId);
        } else if (_order[orderId].side != side) {
            revert OrderSideMismatch(orderId, _order[orderId].side);
        } else if (orderStatus != OrderStatus.New && orderStatus != OrderStatus.Partial) {
            revert UncancellableOrderStatus(orderId, orderStatus);
        }

        /// @dev 주문(Order) 상태 변경 및 삭제
        _order[orderId].ordStatus = OrderStatus.Canceled;
        DoublyLinkedList.remove(_book[token].orderQueue[price], orderId);

        /// @dev 호가창(Quote) 정보 변경
        _book[token].quote[price].orderCntAtPx--;
        _book[token].quote[price].leavesQtyAtPx -= leavesQty;

        if (side == Side.Buy) {
            /// @dev 호가창(Quote)에 주문이 남아 있지 않은 경우
            if (_book[token].quote[price].orderCntAtPx == 0) {
                /// @dev 호가창(Quote)에 삭제
                _book[token].quote[price].side = Side.Null;
                SortedLinkedList.remove(_book[token].bidQuoteList, price);
            }

            /// @dev 오더북(OrderBook) 정보 변경
            _book[token].quoteBidCnt--;
            _book[token].quoteBidQty -= leavesQty;
            _book[token].quoteBidNotional = _book[token].quoteBidNotional - price * leavesQty;
            IERC20Lock(_currencyToken).unlock(_order[orderId].account, leavesQty * price + _order[orderId].tradeFee);
            emit BuyOrderCanceled(orderId, block.timestamp);
        } else if (side == Side.Sell) {
            /// @dev 호가창(Quote)에 주문이 남아 있지 않은 경우
            if (_book[token].quote[price].orderCntAtPx == 0) {
                /// @dev 호가창(Quote)에 삭제
                _book[token].quote[price].side = Side.Null;
                SortedLinkedList.remove(_book[token].askQuoteList, price);
            }

            /// @dev 오더북(OrderBook) 정보 변경
            _book[token].quoteAskCnt--;
            _book[token].quoteAskQty -= leavesQty;
            _book[token].quoteAskNotional = _book[token].quoteAskNotional - price * leavesQty;
            IERC20Lock(token).unlock(_order[orderId].account, leavesQty);
            emit SellOrderCanceled(orderId, block.timestamp);
        }

        return true;
    }

    function _replaceOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty, Side side) private returns (bool) {
        if (qty > _order[oldOrderId].leavesQty) {
            revert OrderExceedingRemainingQuantity(oldOrderId, _order[oldOrderId].leavesQty, qty);
        }

        _cancleOrder(oldOrderId, side);
        _order[oldOrderId].ordStatus = OrderStatus.Replaced;
        _placeOrder(newOrderId, oldOrderId, _order[oldOrderId].account, _order[oldOrderId].token, price, qty, side);

        if (side == Side.Buy) {
            emit BuyOrderReplaced(oldOrderId, newOrderId, block.timestamp);
        } else if (side == Side.Sell) {
            emit SellOrderReplaced(oldOrderId, newOrderId, block.timestamp);
        }

        return true;
    }

    function _trade(uint256 makerOrderId, uint256 takerOrderId, address token, uint256 price, uint256 qty) private returns (uint256) {
        _tradeId++;

        uint256 buyOrderId;
        uint256 sellOrderId;
        address buyer;
        address seller;
        LiquidityInd buyerInd;
        LiquidityInd sellerInd;
        uint256 buyFee;
        uint256 sellFee;

        if (_order[makerOrderId].side == Side.Buy) {
            buyOrderId = makerOrderId;
            sellOrderId = takerOrderId;
            buyerInd = LiquidityInd.Maker;
            sellerInd = LiquidityInd.Taker;
        } else if (_order[makerOrderId].side == Side.Sell) {
            buyOrderId = takerOrderId;
            sellOrderId = makerOrderId;
            buyerInd = LiquidityInd.Taker;
            sellerInd = LiquidityInd.Maker;
        }

        buyer = _order[buyOrderId].account;
        seller = _order[sellOrderId].account;
        IERC20Lock(token).unlockTransfer(seller, buyer, qty);

        if (_order[buyOrderId].tradeFee > 0) {
            if (_order[buyOrderId].leavesQty == qty) {
                buyFee = _order[buyOrderId].tradeFee;
                _order[buyOrderId].tradeFee = 0;
            } else {
                buyFee = _getFee(price * qty, _buyFee);
                _order[buyOrderId].tradeFee -= buyFee;
            }
        }

        if (_order[sellOrderId].tradeFee > 0) {
            if (_order[sellOrderId].leavesQty == qty) {
                sellFee = _order[sellOrderId].tradeFee;
                _order[sellOrderId].tradeFee = 0;
            } else {
                sellFee = _getFee(price * qty, _sellFee);
                _order[sellOrderId].tradeFee -= sellFee;
            }
        }

        if (buyFee > 0 || sellFee > 0) {
            IERC20Lock(_currencyToken).unlockTransferWithFee(buyer, seller, msg.sender, price * qty + buyFee, buyFee, sellFee);
        } else {
            IERC20Lock(_currencyToken).unlockTransfer(buyer, seller, price * qty);
        }

        emit OrderMatched(_tradeId, buyOrderId, buyerInd, sellOrderId, sellerInd, token, price, qty, price * qty, buyFee, sellFee, block.timestamp);

        return _tradeId;
    }

    function _getFee(uint256 tradeNotional, Fee memory fee) private pure returns (uint256) {
        uint256 denominator = 10**(fee.decimal+2);
        if (fee.round) {
            return (tradeNotional * fee.feeRatio + denominator - 1) / denominator;
        } else {
            return tradeNotional * fee.feeRatio / denominator;
        }
    }
}


// import "./STOMatchingStruct.sol";
// import {ISTOMatching} from "./ISTOMatching.sol";
// import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
// import {IERC20Lock} from "../token/extension/IERC20Lock.sol";

// contract STOMatching is ISTOMatching, AccessControl {
//     bytes32 public constant TRADE_ADMIN_ROLE = keccak256("TRADE_ADMIN_ROLE");

//     /// 주문 아이디 (global unique) => 주문 구조체
//     mapping (uint256 => Order) internal _order;
//     /// 증권토큰 컨트랙트 주소 => 오더북 구조체
//     mapping (address => OrderBook) internal _book;
//     /// 거래 아이디 (global unique)
//     uint256 internal _tradeId;
//     /// 거래 정보
//     mapping (uint256 => Trade) internal _tradeInfo;
//     /// 결제 토큰 컨트랙트
//     address internal _currencyToken;
//     /// 매수 거래 수수료
//     Fee internal _buyFee;
//     /// 매도 거래 수수료
//     Fee internal _sellFee;

//     constructor(address currencyToken) {
//         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _grantRole(TRADE_ADMIN_ROLE, msg.sender);

//         _currencyToken = currencyToken;
//         setBuyFee(0, 1, msg.sender, true);
//         setSellFee(0, 1, msg.sender, false);
//     }

//     function placeBuyOrder(uint256 orderId, address account, address token, uint256 price, uint256 qty) external virtual onlyRole(TRADE_ADMIN_ROLE) returns (bool) {
//         return _placeOrder(orderId, 0, account, token, price, qty, Side.Buy);
//     }

//     function placeSellOrder(uint256 orderId, address account, address token, uint256 price, uint256 qty) external virtual onlyRole(TRADE_ADMIN_ROLE) returns (bool) {
//         return _placeOrder(orderId, 0, account, token, price, qty, Side.Sell);
//     }

//     function cancelBuyOrder(uint256 orderId) external virtual onlyRole(TRADE_ADMIN_ROLE) returns (bool) {
//         return _cancleOrder(orderId, Side.Buy);
//     }

//     function cancelSellOrder(uint256 orderId) external virtual onlyRole(TRADE_ADMIN_ROLE) returns (bool) {
//         return _cancleOrder(orderId, Side.Sell);
//     }

//     function replaceBuyOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external virtual onlyRole(TRADE_ADMIN_ROLE) returns (bool) {
//         return _replaceOrder(oldOrderId, newOrderId, price, qty, Side.Buy);
//     }

//     function replaceSellOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty) external virtual onlyRole(TRADE_ADMIN_ROLE) returns (bool) {
//         return _replaceOrder(oldOrderId, newOrderId, price, qty, Side.Sell);
//     }

//     function setBuyFee(uint256 feeRatio, uint256 decimal, address feeAccount, bool round) public virtual onlyRole(TRADE_ADMIN_ROLE) {
//         _buyFee = Fee({
//             feeRatio: feeRatio,
//             decimal: decimal,
//             feeAccount: feeAccount,
//             round: round
//         });
//     }

//     function setSellFee(uint256 feeRatio, uint256 decimal, address feeAccount, bool round) public virtual onlyRole(TRADE_ADMIN_ROLE) {
//         _sellFee = Fee({
//             feeRatio: feeRatio,
//             decimal: decimal,
//             feeAccount: feeAccount,
//             round: round
//         });
//     }

//     function getOrder(uint256 orderId) external view virtual returns (Order memory) {
//         return _order[orderId];
//     }

//     function getOrderBatch(uint256[] memory orderId) external view virtual returns (Order[] memory) {
//         uint256 length = orderId.length;
//         Order[] memory order = new Order[](length);

//         for (uint256 i=0; i<length; i++) {
//             order[i] = _order[orderId[i]];
//         }

//         return order;
//     }

//     function getQuoteOrders(address token, uint256 price) external view virtual returns (Quote memory, Order[] memory) {
//         uint256 length = DoublyLinkedList.length(_book[token].orderQueue[price]);
//         Order[] memory order = new Order[](length);
//         uint256 tmpOrdId = _book[token].orderQueue[price].head;

//         for (uint256 i=0; i<length; i++) {
//             order[i] = _order[tmpOrdId];
//             tmpOrdId = _book[token].orderQueue[price].next[tmpOrdId];
//         }

//         return (_book[token].quote[price], order);
//     }

//     function getAllQuoteList(address token) external view virtual returns (Quote[] memory, Quote[] memory) {
//         uint256 asklength = SortedLinkedList.length(_book[token].askQuoteList);
//         uint256 bidlength = SortedLinkedList.length(_book[token].bidQuoteList);
//         Quote[] memory askQuoteList = new Quote[](asklength);
//         Quote[] memory bidQuoteList = new Quote[](bidlength);

//         uint256 tmpPrice = _book[token].askQuoteList.tail;
//         for (uint256 i=0; i<asklength; i++) {
//             askQuoteList[i] = _book[token].quote[tmpPrice];
//             tmpPrice = _book[token].askQuoteList.prev[tmpPrice];
//         }

//         tmpPrice = _book[token].bidQuoteList.tail;
//         for (uint256 i=0; i<bidlength; i++) {
//             bidQuoteList[i] = _book[token].quote[tmpPrice];
//             tmpPrice = _book[token].bidQuoteList.prev[tmpPrice];
//         }

//         return (askQuoteList, bidQuoteList);
//     }

//     function getOrderBook(address token) external view virtual returns (uint256[] memory) {
//         uint256[] memory orderBookInfo = new uint256[](16);

//         orderBookInfo[0] = _book[token].quoteBidCnt;
//         orderBookInfo[1] = _book[token].quoteBidQty;
//         orderBookInfo[2] = _book[token].quoteBidNotional;
//         orderBookInfo[3] = _book[token].quoteAskCnt;
//         orderBookInfo[4] = _book[token].quoteAskQty;
//         orderBookInfo[5] = _book[token].quoteAskNotional;
//         orderBookInfo[6] = _book[token].bidQuoteList.head;
//         orderBookInfo[7] = _book[token].bidQuoteList.tail;
//         orderBookInfo[8] = _book[token].askQuoteList.head;
//         orderBookInfo[9] = _book[token].askQuoteList.tail;
//         orderBookInfo[10] = _book[token].tradeMinPrice;
//         orderBookInfo[11] = _book[token].tradeMaxPrice;
//         orderBookInfo[12] = _book[token].tradeLastPrice;
//         orderBookInfo[13] = _book[token].tradeAvgPrice;
//         orderBookInfo[14] = _book[token].totalTradeQty;
//         orderBookInfo[15] = _book[token].totalTradeNotional;

//         return orderBookInfo;
//     }

//     function _placeOrder(uint256 orderId, uint256 oldOrderId, address account, address token, uint256 price, uint256 qty, Side side) private returns (bool) {
//         if (token == address(0)) {
//             revert ZeroAddressToken();
//         } else if (account == address(0)) {
//             revert ZeroAddressAccount();
//         } else if (price == 0) {
//             revert ZeroOrderPrice();
//         } else if (qty == 0) {
//             revert ZeroOrderQuantity();
//         } else if (_order[orderId].orderId != 0) {
//             revert DuplicateOrderId(orderId);
//         }

//         uint256 tradeFee;

//         if (side == Side.Buy) {
//             tradeFee = _getFee(price * qty, _buyFee);
//         } else if (side == Side.Sell) {
//             tradeFee = _getFee(price * qty, _sellFee);
//         }

//         _order[orderId] = Order({
//             orderId: orderId,
//             origClOrdId: oldOrderId,
//             account: account,
//             side: side,
//             ordStatus: OrderStatus.New,
//             token: token,
//             price: price,
//             orderQty: qty,
//             cumQty: 0,
//             leavesQty: qty,
//             tradeFee: tradeFee,
//             timestamp: block.timestamp
//         });

//         Side oldSide = _book[token].quote[price].side;

//         if (oldSide == Side.Null) {
//             if (side == Side.Buy) {
//                 IERC20Lock(_currencyToken).lock(account, qty * price + tradeFee);
//                 _book[token].quoteBidCnt++;
//                 _book[token].quoteBidQty += qty;
//                 _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qty;
//                 SortedLinkedList.insertSortedDsc(_book[token].bidQuoteList, price);
//                 emit BuyOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
//             } else if (side == Side.Sell) {
//                 IERC20Lock(token).lock(account, qty);
//                 _book[token].quoteAskCnt++;
//                 _book[token].quoteAskQty += qty;
//                 _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qty;
//                 SortedLinkedList.insertSortedAsc(_book[token].askQuoteList, price);
//                 emit SellOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
//             }

//             _book[token].quote[price].side = side;
//             _book[token].quote[price].price = price;
//             _book[token].quote[price].orderCntAtPx++;
//             _book[token].quote[price].leavesQtyAtPx += qty;
//             DoublyLinkedList.insert(_book[token].orderQueue[price], orderId);
//         } else if (oldSide == side) {
//             if (side == Side.Buy) {
//                 IERC20Lock(_currencyToken).lock(account, qty * price + tradeFee);
//                 _book[token].quoteBidCnt++;
//                 _book[token].quoteBidQty += qty;
//                 _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qty;
//                 emit BuyOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
//             } else if (side == Side.Sell) {
//                 IERC20Lock(token).lock(account, qty);
//                 _book[token].quoteAskCnt++;
//                 _book[token].quoteAskQty += qty;
//                 _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qty;
//                 emit SellOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
//             }

//             _book[token].quote[price].orderCntAtPx++;
//             _book[token].quote[price].leavesQtyAtPx += qty;
//             DoublyLinkedList.insert(_book[token].orderQueue[price], orderId);
//         } else {
//             if (side == Side.Buy) {
//                 IERC20Lock(_currencyToken).lock(account, qty * price + tradeFee);
//                 emit BuyOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
//                 // _book[token].quoteBidCnt++;
//                 // _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qty;
//             } else if (side == Side.Sell) {
//                 IERC20Lock(token).lock(account, qty);
//                 emit SellOrderPlaced(orderId, account, token, price, qty, tradeFee, block.timestamp);
//                 // _book[token].quoteAskCnt++;
//                 // _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qty;
//             }

//             uint256 qtyRemain = qty;
//             uint256 tmpOrdId = _book[token].orderQueue[price].head;

//             while (tmpOrdId != 0) {
//                 if (_order[tmpOrdId].leavesQty > qtyRemain) {
//                     /// @dev TODO: implements `_trade` logic
//                     _trade(tmpOrdId, orderId, token, price, qtyRemain);

//                     /// @dev 매칭에 의한 오더북(OrderBook) 정보 변경
//                     if (side == Side.Buy) {
//                         _book[token].quoteAskQty -= qtyRemain;
//                         _book[token].quoteAskNotional = _book[token].quoteAskNotional - price * qtyRemain;
//                     } else if (side == Side.Sell) {
//                         _book[token].quoteBidQty -= qtyRemain;
//                         _book[token].quoteBidNotional = _book[token].quoteBidNotional - price * qtyRemain;
//                     }

//                     /// @dev 매칭에 의한 호가창(Quote) 정보 변경
//                     _book[token].quote[price].cumQtyAtPx += qtyRemain;
//                     _book[token].quote[price].leavesQtyAtPx -= qtyRemain;

//                     /// @dev 매칭에 의한 기존 주문(Order) 정보 변경
//                     _order[tmpOrdId].ordStatus = OrderStatus.Partial;
//                     _order[tmpOrdId].cumQty += qtyRemain;
//                     _order[tmpOrdId].leavesQty -= qtyRemain;

//                     /// @dev 주문 전량 처리 완료
//                     qtyRemain = 0;
//                     break;
//                 } else {
//                     /// @dev TODO: implements `_trade` logic
//                     _trade(tmpOrdId, orderId, token, price, _order[tmpOrdId].leavesQty);

//                     /// @dev 남은 주문 수량 처리
//                     qtyRemain -= _order[tmpOrdId].leavesQty;

//                     /// @dev 매칭에 의한 오더북(OrderBook) 정보 변경
//                     if (side == Side.Buy) {
//                         _book[token].quoteAskCnt--;
//                         _book[token].quoteAskQty -= _order[tmpOrdId].leavesQty;
//                         _book[token].quoteAskNotional = _book[token].quoteAskNotional - price * _order[tmpOrdId].leavesQty;
//                     } else if (side == Side.Sell) {
//                         _book[token].quoteBidCnt--;
//                         _book[token].quoteBidQty -= _order[tmpOrdId].leavesQty;
//                         _book[token].quoteBidNotional = _book[token].quoteBidNotional - price * _order[tmpOrdId].leavesQty;
//                     }

//                     /// @dev 매칭에 의한 호가창(Quote) 정보 변경
//                     _book[token].quote[price].orderCntAtPx--;
//                     _book[token].quote[price].cumQtyAtPx += _order[tmpOrdId].leavesQty;
//                     _book[token].quote[price].leavesQtyAtPx -= _order[tmpOrdId].leavesQty;

//                     /// @dev 매칭에 의한 기존 주문(Order) 정보 변경
//                     _order[tmpOrdId].ordStatus = OrderStatus.Filled;
//                     _order[tmpOrdId].cumQty = _order[tmpOrdId].orderQty;
//                     _order[tmpOrdId].leavesQty = 0;
//                 }

//                 uint256 beforeTmpOrdId = tmpOrdId;
//                 tmpOrdId = _book[token].orderQueue[price].next[tmpOrdId];
//                 DoublyLinkedList.remove(_book[token].orderQueue[price], beforeTmpOrdId);
//             }

//             if (qtyRemain > 0) {
//                 /// @dev 매칭 후 잔량에 의한 오더북(OrderBook) 정보 변경
//                 if (side == Side.Buy) {
//                     _book[token].quoteBidCnt++;
//                     _book[token].quoteBidQty += qtyRemain;
//                     _book[token].quoteBidNotional = _book[token].quoteBidNotional + price * qtyRemain;
//                     SortedLinkedList.remove(_book[token].askQuoteList, price);
//                     SortedLinkedList.insertSortedDsc(_book[token].bidQuoteList, price);
//                 } else if (side == Side.Sell) {
//                     _book[token].quoteAskCnt++;
//                     _book[token].quoteAskQty += qtyRemain;
//                     _book[token].quoteAskNotional = _book[token].quoteAskNotional + price * qtyRemain;
//                     SortedLinkedList.remove(_book[token].bidQuoteList, price);
//                     SortedLinkedList.insertSortedAsc(_book[token].askQuoteList, price);
//                 }

//                 /// @dev 주문 수량이 호가창 잔량보다 많아 매칭 후 신규(side 반대) 주문 호가창 추가
//                 _book[token].quote[price].side = side;
//                 _book[token].quote[price].orderCntAtPx = 1;
//                 _book[token].quote[price].leavesQtyAtPx = qtyRemain;
//                 DoublyLinkedList.insert(_book[token].orderQueue[price], orderId);

//                 /// @dev 주문(Order) 정보 수정
//                 _order[orderId].cumQty = _order[orderId].orderQty - qtyRemain;
//                 _order[orderId].leavesQty = qtyRemain;
//                 _order[orderId].ordStatus = OrderStatus.Partial;
//             } else {
//                 /// @dev 주문(Order) 정보 수정
//                 _order[orderId].cumQty = _order[orderId].orderQty;
//                 _order[orderId].leavesQty = 0;
//                 _order[orderId].ordStatus = OrderStatus.Filled;
//             }

//             if (_book[token].quote[price].orderCntAtPx == 0) {
//                 /// @dev 주문 수량과 호가창 잔량이 정확히 일치하여 해당 호가창 삭제
//                 _book[token].quote[price].side = Side.Null;

//                 /// @dev TODO: 해당 호가창 리스트에서 삭제하는 로직 구현
//                 if (SortedLinkedList.exists(_book[token].askQuoteList, price)) {
//                     SortedLinkedList.remove(_book[token].askQuoteList, price);
//                 }

//                 if (SortedLinkedList.exists(_book[token].bidQuoteList, price)) {
//                     SortedLinkedList.remove(_book[token].bidQuoteList, price);
//                 }
//             }

//             if (price < _book[token].tradeMinPrice || _book[token].tradeMinPrice == 0) {
//                 _book[token].tradeMinPrice = price;
//             }

//             if (price > _book[token].tradeMaxPrice || _book[token].tradeMaxPrice == 0) {
//                 _book[token].tradeMaxPrice = price;
//             }

//             /// @dev TODO: implements trade result
//             uint256 qtyTrade = qty - qtyRemain;
//             _book[token].tradeLastPrice = price;
//             _book[token].tradeAvgPrice = (_book[token].totalTradeNotional + price * qtyTrade) / (_book[token].totalTradeQty + qtyTrade);
//             _book[token].totalTradeQty += qtyTrade;
//             _book[token].totalTradeNotional = _book[token].totalTradeNotional + price * qtyTrade;
//         }

//         return true;
//     }

//     function _cancleOrder(uint256 orderId, Side side) private returns (bool) {
//         address token = _order[orderId].token;
//         uint256 price = _order[orderId].price;
//         uint256 leavesQty = _order[orderId].leavesQty;
//         OrderStatus orderStatus = _order[orderId].ordStatus;

//         if (_order[orderId].account == address(0)) {
//             revert OrderIdNotFound(orderId);
//         } else if (_order[orderId].side != side) {
//             revert OrderSideMismatch(orderId, _order[orderId].side);
//         } else if (orderStatus != OrderStatus.New && orderStatus != OrderStatus.Partial) {
//             revert UncancellableOrderStatus(orderId, orderStatus);
//         }

//         /// @dev 주문(Order) 상태 변경 및 삭제
//         _order[orderId].ordStatus = OrderStatus.Canceled;
//         DoublyLinkedList.remove(_book[token].orderQueue[price], orderId);

//         /// @dev 호가창(Quote) 정보 변경
//         _book[token].quote[price].orderCntAtPx--;
//         _book[token].quote[price].leavesQtyAtPx -= leavesQty;

//         if (side == Side.Buy) {
//             /// @dev 호가창(Quote)에 주문이 남아 있지 않은 경우
//             if (_book[token].quote[price].orderCntAtPx == 0) {
//                 /// @dev 호가창(Quote)에 삭제
//                 _book[token].quote[price].side = Side.Null;
//                 SortedLinkedList.remove(_book[token].bidQuoteList, price);
//             }

//             /// @dev 오더북(OrderBook) 정보 변경
//             _book[token].quoteBidCnt--;
//             _book[token].quoteBidQty -= leavesQty;
//             _book[token].quoteBidNotional = _book[token].quoteBidNotional - price * leavesQty;
//             IERC20Lock(_currencyToken).unlock(_order[orderId].account, leavesQty * price + _order[orderId].tradeFee);
//             emit BuyOrderCanceled(orderId, block.timestamp);
//         } else if (side == Side.Sell) {
//             /// @dev 호가창(Quote)에 주문이 남아 있지 않은 경우
//             if (_book[token].quote[price].orderCntAtPx == 0) {
//                 /// @dev 호가창(Quote)에 삭제
//                 _book[token].quote[price].side = Side.Null;
//                 SortedLinkedList.remove(_book[token].askQuoteList, price);
//             }

//             /// @dev 오더북(OrderBook) 정보 변경
//             _book[token].quoteAskCnt--;
//             _book[token].quoteAskQty -= leavesQty;
//             _book[token].quoteAskNotional = _book[token].quoteAskNotional - price * leavesQty;
//             IERC20Lock(token).unlock(_order[orderId].account, leavesQty);
//             emit SellOrderCanceled(orderId, block.timestamp);
//         }

//         return true;
//     }

//     function _replaceOrder(uint256 oldOrderId, uint256 newOrderId, uint256 price, uint256 qty, Side side) private returns (bool) {
//         if (qty > _order[oldOrderId].leavesQty) {
//             revert OrderExceedingRemainingQuantity(oldOrderId, _order[oldOrderId].leavesQty, qty);
//         }

//         _cancleOrder(oldOrderId, side);
//         _order[oldOrderId].ordStatus = OrderStatus.Replaced;
//         _placeOrder(newOrderId, oldOrderId, _order[oldOrderId].account, _order[oldOrderId].token, price, qty, side);

//         if (side == Side.Buy) {
//             emit BuyOrderReplaced(oldOrderId, newOrderId, block.timestamp);
//         } else if (side == Side.Sell) {
//             emit SellOrderReplaced(oldOrderId, newOrderId, block.timestamp);
//         }

//         return true;
//     }

//     function _trade(uint256 makerOrderId, uint256 takerOrderId, address token, uint256 price, uint256 qty) private returns (uint256) {
//         _tradeId++;

//         uint256 buyOrderId;
//         uint256 sellOrderId;
//         address buyer;
//         address seller;
//         LiquidityInd buyerInd;
//         LiquidityInd sellerInd;
//         uint256 buyFee;
//         uint256 sellFee;

//         if (_order[makerOrderId].side == Side.Buy) {
//             buyOrderId = makerOrderId;
//             sellOrderId = takerOrderId;
//             buyerInd = LiquidityInd.Maker;
//             sellerInd = LiquidityInd.Taker;
//         } else if (_order[makerOrderId].side == Side.Sell) {
//             buyOrderId = takerOrderId;
//             sellOrderId = makerOrderId;
//             buyerInd = LiquidityInd.Taker;
//             sellerInd = LiquidityInd.Maker;
//         }

//         buyer = _order[buyOrderId].account;
//         seller = _order[sellOrderId].account;
//         IERC20Lock(token).unlockTransfer(seller, buyer, qty);

//         if (_order[buyOrderId].tradeFee > 0) {
//             if (_order[buyOrderId].leavesQty == qty) {
//                 buyFee = _order[buyOrderId].tradeFee;
//                 _order[buyOrderId].tradeFee = 0;
//             } else {
//                 buyFee = _getFee(price * qty, _buyFee);
//                 _order[buyOrderId].tradeFee -= buyFee;
//             }
//         }

//         if (_order[sellOrderId].tradeFee > 0) {
//             if (_order[sellOrderId].leavesQty == qty) {
//                 sellFee = _order[sellOrderId].tradeFee;
//                 _order[sellOrderId].tradeFee = 0;
//             } else {
//                 sellFee = _getFee(price * qty, _sellFee);
//                 _order[sellOrderId].tradeFee -= sellFee;
//             }
//         }

//         if (buyFee > 0 || sellFee > 0) {
//             IERC20Lock(_currencyToken).unlockTransferWithFee(buyer, seller, msg.sender, price * qty + buyFee, buyFee, sellFee);
//         } else {
//             IERC20Lock(_currencyToken).unlockTransfer(buyer, seller, price * qty);
//         }

//         emit OrderMatched(_tradeId, buyOrderId, buyerInd, sellOrderId, sellerInd, token, price, qty, price * qty, buyFee, sellFee, block.timestamp);

//         return _tradeId;
//     }

//     function _getFee(uint256 tradeNotional, Fee memory fee) private pure returns (uint256) {
//         uint256 denominator = 10**(fee.decimal+2);
//         if (fee.round) {
//             return (tradeNotional * fee.feeRatio + denominator - 1) / denominator;
//         } else {
//             return tradeNotional * fee.feeRatio / denominator;
//         }
//     }
// }