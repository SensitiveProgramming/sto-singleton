import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { translateData } from "./common";

interface Order {
    orderId:string;
    origClOrdId:string;
    account:string;
    side:string;
    ordStatus:string;
    token:string;
    price:string;
    orderQty:string;
    cumQty:string;
    leavesQty:string;
    tradeFee:string;
}

interface Quote {
    side:string;
    price:string;
    orderCnt:string;
    cumQty:string;
    leavesQty:string;
    notional:string;
}

interface OrderBook {
    quoteBidCnt:string;
    quoteBidQty:string;
    quoteBidNotional:string;
    quoteAskCnt:string;
    quoteAskQty:string;
    quoteAskNotional:string;
    quoteMinBid:string;
    quoteMaxBid:string;
    quoteMinAsk:string;
    quoteMaxAsk:string;
    tradeMinPrice:string;
    tradeMaxPrice:string;
    tradeLastPrice:string;
    tradeAvgPrice:string;
    totalTradeQty:string;
    totalTradeNotional:string;
}

let ctAddress:string;
let stAddress:string;
let matchingAddress:string;

export function setContractAddress(currencyToken:any, securityToken:any, matchingContract:any) {
    ctAddress = currencyToken.toString();
    stAddress = securityToken.toString();
    matchingAddress = matchingContract.toString();
}

export async function printOrderBook() {
    const matching = await ethers.getContractAt("STOMatching", matchingAddress);
    let data = await matching.getOrderBook(stAddress);

    let orderbook:OrderBook = {
        quoteBidCnt: data[0].toString(),
        quoteBidQty: data[1].toString(),
        quoteBidNotional: data[2].toString(),
        quoteAskCnt: data[3].toString(),
        quoteAskQty: data[4].toString(),
        quoteAskNotional: data[5].toString(),
        quoteMinBid: data[6].toString(),
        quoteMaxBid: data[7].toString(),
        quoteMinAsk: data[8].toString(),
        quoteMaxAsk: data[9].toString(),
        tradeMinPrice: data[10].toString(),
        tradeMaxPrice: data[11].toString(),
        tradeLastPrice: data[12].toString(),
        tradeAvgPrice: data[13].toString(),
        totalTradeQty: data[14].toString(),
        totalTradeNotional: data[15].toString(),
    }

    console.log("[OrderBook]");
    console.table(orderbook);
    console.log("");
}

export async function printQuoteList() {
    const matching = await ethers.getContractAt("STOMatching", matchingAddress.toString());
    let [ask, bid] = await matching.getAllQuoteList(stAddress);
    let askCnt = ask.length;
    let bidCnt = bid.length;
    let askIdx = 0;
    let bidIdx = 0;
    let tbData:Quote[] = [];

    while (askIdx != askCnt || bidIdx != bidCnt) {
        if (askIdx == askCnt) {
            let tb:Quote = {
                side: "[Bid]",
                price: bid[bidIdx][1].toString(),
                orderCnt: bid[bidIdx][2].toString(),
                cumQty: bid[bidIdx][3].toString(),
                leavesQty: bid[bidIdx][4].toString(),
                notional: (bid[bidIdx][1]*bid[bidIdx][4]).toString(),
            }
            tbData.push(tb);
            bidIdx++;
            continue;
        } else if (bidIdx == bidCnt) {
            let tb:Quote = {
                side: "[Ask]",
                price: ask[askIdx][1].toString(),
                orderCnt: ask[askIdx][2].toString(),
                cumQty: ask[askIdx][3].toString(),
                leavesQty: ask[askIdx][4].toString(),
                notional: (ask[askIdx][1]*ask[askIdx][4]).toString(),
            }
            tbData.push(tb);
            askIdx++;
            continue;
        }

        if (ask[askIdx][1] > bid[bidIdx][1]) {
            let tb:Quote = {
                side: "[Ask]",
                price: ask[askIdx][1].toString(),
                orderCnt: ask[askIdx][2].toString(),
                cumQty: ask[askIdx][3].toString(),
                leavesQty: ask[askIdx][4].toString(),
                notional: (ask[askIdx][1]*ask[askIdx][4]).toString(),
            }
            tbData.push(tb);
            askIdx++;
        } else if (ask[askIdx][1] < bid[bidIdx][1]) {
            let tb:Quote = {
                side: "[Bid]",
                price: bid[bidIdx][1].toString(),
                orderCnt: bid[bidIdx][2].toString(),
                cumQty: bid[bidIdx][3].toString(),
                leavesQty: bid[bidIdx][4].toString(),
                notional: (bid[bidIdx][1]*bid[bidIdx][4]).toString(),
            }
            tbData.push(tb);
            bidIdx++;
        }
    }

    console.log("[QuoteList] Ask: " + askCnt + ", Bid: " + bidCnt);
    if (tbData.length == 0) {
        return;
    }
    consoleTable(tbData);
    console.log("");
}

export async function printAllOrders(user:HardhatEthersSigner[]) {
    const matching = await ethers.getContractAt("STOMatching", matchingAddress.toString());
    let tbData:Order[] = [];

    for (let i=1; i<=100; i++) {
        let order = await matching.getOrder(i);
        if (order[0].toString() == "0") {
            continue;
        }
    
        let side:string = "";
        if (order[3] == BigInt(0)) {
            side = "Null";
        } else if (order[3] == BigInt(1)) {
            side = "Buy";
        } else if (order[3] == BigInt(2)) {
            side = "Sell";
        }

        let orderStatus:string = "";
        if (order[4] == BigInt(1)) {
            orderStatus = "New";
        } else if (order[4] == BigInt(2)) {
            orderStatus = "Partial";
        } else if (order[4] == BigInt(3)) {
            orderStatus = "Filled";
        } else if (order[4] == BigInt(4)) {
            orderStatus = "Canceled";
        } else if (order[4] == BigInt(5)) {
            orderStatus = "Replaced";
        } else if (order[4] == BigInt(6)) {
            orderStatus = "Rejected";
        }

        let account:string = "";
        if (order[2].toString() == user[0].address.toString()) {
            account = "user1";
        } else if (order[2].toString() == user[1].address.toString()) {
            account = "user2";
        } else if (order[2].toString() == user[2].address.toString()) {
            account = "user3";
        } else if (order[2].toString() == user[3].address.toString()) {
            account = "user4";
        } else if (order[2].toString() == user[4].address.toString()) {
            account = "user5";
        } else {
            account = order[2].toString().substring(0, 6) + "..." + order[2].toString().substring(38, 42);
        }

        let tb:Order = {
            orderId: order[0].toString(),
            origClOrdId: order[1].toString(),
            account: account.toString(),//order[2].toString().substring(0, 6) + "..." + order[2].toString().substring(38, 42),
            side: side,// + " (" + order[3].toString() + ")",
            ordStatus: orderStatus,// + " (" + order[4].toString() + ")",
            token: order[5].toString().substring(0, 6) + "..." + order[5].toString().substring(38, 42),
            price: order[6].toString(),
            orderQty: order[7].toString(),
            cumQty: order[8].toString(),
            leavesQty: order[9].toString(),
            tradeFee: order[10].toString(),
            // timestamp: order[11].toString(),
        }

        tbData.push(tb);
    }

    console.log("[AllOrders]");
    consoleTable2(tbData);
    console.log("");
}

export async function printQuoteOrderList(user:HardhatEthersSigner[]) {
    const matching = await ethers.getContractAt("STOMatching", matchingAddress.toString());
    let [ask, bid] = await matching.getAllQuoteList(stAddress.toString());
    let askCnt = ask.length;
    let bidCnt = bid.length;
    let askIdx = 0;
    let bidIdx = 0;

    console.log("[QuoteList] Ask: " + askCnt + ", Bid: " + bidCnt);

    while (askIdx != askCnt || bidIdx != bidCnt) {
        if (askIdx == askCnt) {
            let tbData:Quote[] = [];
            let tb:Quote = {
                side: "[Bid]",
                price: bid[bidIdx][1].toString(),
                orderCnt: bid[bidIdx][2].toString(),
                cumQty: bid[bidIdx][3].toString(),
                leavesQty: bid[bidIdx][4].toString(),
                notional: (bid[bidIdx][1]*bid[bidIdx][4]).toString(),
            }
            tbData.push(tb);
            consoleTable(tbData);
            console.log("--------------------------------------------------------------");
            await printOrdersPrice(bid[bidIdx][1], user);
            bidIdx++;
            continue;
        } else if (bidIdx == bidCnt) {
            let tbData:Quote[] = [];
            let tb:Quote = {
                side: "[Ask]",
                price: ask[askIdx][1].toString(),
                orderCnt: ask[askIdx][2].toString(),
                cumQty: ask[askIdx][3].toString(),
                leavesQty: ask[askIdx][4].toString(),
                notional: (ask[askIdx][1]*ask[askIdx][4]).toString(),
            }
            tbData.push(tb);
            consoleTable(tbData);
            console.log("--------------------------------------------------------------");
            await printOrdersPrice(ask[askIdx][1], user);
            askIdx++;
            continue;
        }

        if (ask[askIdx][1] > bid[bidIdx][1]) {
            let tbData:Quote[] = [];
            let tb:Quote = {
                side: "[Ask]",
                price: ask[askIdx][1].toString(),
                orderCnt: ask[askIdx][2].toString(),
                cumQty: ask[askIdx][3].toString(),
                leavesQty: ask[askIdx][4].toString(),
                notional: (ask[askIdx][1]*ask[askIdx][4]).toString(),
            }
            tbData.push(tb);
            consoleTable(tbData);
            console.log("--------------------------------------------------------------");
            await printOrdersPrice(ask[askIdx][1], user);
            askIdx++;
        } else if (ask[askIdx][1] < bid[bidIdx][1]) {
            let tbData:Quote[] = [];
            let tb:Quote = {
                side: "[Bid]",
                price: bid[bidIdx][1].toString(),
                orderCnt: bid[bidIdx][2].toString(),
                cumQty: bid[bidIdx][3].toString(),
                leavesQty: bid[bidIdx][4].toString(),
                notional: (bid[bidIdx][1]*bid[bidIdx][4]).toString(),
            }
            tbData.push(tb);
            consoleTable(tbData);
            console.log("--------------------------------------------------------------");
            await printOrdersPrice(bid[bidIdx][1], user);
            bidIdx++;
        }
    }
}

export async function printOrdersPrice(price:any, user:HardhatEthersSigner[]) {
    const matching = await ethers.getContractAt("STOMatching", matchingAddress.toString());
    let [, order] = await matching.getQuoteOrders(stAddress.toString(), price);
    let length = order.length;
    let tbData:Order[] = [];

    for (let i=0; i<length; i++) {
        let side:string = "";
        if (order[i][3] == BigInt(0)) {
            side = "Null";
        } else if (order[i][3] == BigInt(1)) {
            side = "Buy";
        } else if (order[i][3] == BigInt(2)) {
            side = "Sell";
        }

        let orderStatus:string = "";
        if (order[i][4] == BigInt(1)) {
            orderStatus = "New";
        } else if (order[i][4] == BigInt(2)) {
            orderStatus = "Partial";
        } else if (order[i][4] == BigInt(3)) {
            orderStatus = "Filled";
        } else if (order[i][4] == BigInt(4)) {
            orderStatus = "Canceled";
        } else if (order[i][4] == BigInt(5)) {
            orderStatus = "Replaced";
        } else if (order[i][4] == BigInt(6)) {
            orderStatus = "Rejected";
        }

        let account:string = "";
        if (order[i][2].toString() == user[0].address.toString()) {
            account = "user1";
        } else if (order[i][2].toString() == user[1].address.toString()) {
            account = "user2";
        } else if (order[i][2].toString() == user[2].address.toString()) {
            account = "user3";
        } else if (order[i][2].toString() == user[3].address.toString()) {
            account = "user4";
        } else if (order[i][2].toString() == user[4].address.toString()) {
            account = "user5";
        }

        let tb:Order = {
            orderId: order[i][0].toString(),
            origClOrdId: order[i][1].toString(),
            account: account.toString(),//order[2].toString().substring(0, 6) + "..." + order[2].toString().substring(38, 42),
            side: side,// + " (" + order[3].toString() + ")",
            ordStatus: orderStatus,// + " (" + order[4].toString() + ")",
            token: order[i][5].toString().substring(0, 6) + "..." + order[i][5].toString().substring(38, 42),
            price: order[i][6].toString(),
            orderQty: order[i][7].toString(),
            cumQty: order[i][8].toString(),
            leavesQty: order[i][9].toString(),
            tradeFee: order[i][10].toString(),
            // timestamp: order[11].toString(),
        }

        tbData.push(tb);
    }

    consoleTable2(tbData);
    console.log("");
}

export async function printAllEvent(txHash:string, printJson:boolean) {
    let dir = path.resolve(__dirname, "../artifacts/contracts/STOMatching.sol/STOMatching.json");
    let file = fs.readFileSync(dir, 'utf-8');
    let json = JSON.parse(file);
    let abiMatch = json.abi;

    dir = path.resolve(__dirname, "../artifacts/contracts/STOMatching.sol/STOMatching.json");
    file = fs.readFileSync(dir, 'utf-8');
    json = JSON.parse(file);
    let abiLock = json.abi;
    let result;

    try {
        result = await ethers.provider.send("eth_getTransactionReceipt", [
            txHash
        ]);

        if (printJson) {
            console.log("\u001b[1;34m[eth_getTransactionReceipt]\u001b[0m");
            console.log(result);
        }

        let ifaceMatching = new ethers.Interface(abiMatch);
        let ifaceLock = new ethers.Interface(abiLock);

        for (let j=0; j<result.logs.length; j++) {
            const eventSelector = result.logs[j].topics[0];
            let eventName;
            let eachLog;
            let isMatch = false;

            try {
                eventName = ifaceMatching.getEventName(eventSelector);
                eachLog = ifaceMatching.parseLog(result.logs[j]);
                isMatch = true;
            } catch(error) {
                if (error instanceof TypeError) {
                    // console.log("기타이벤트");
                    // console.log(error.message);
                    eventName = ifaceLock.getEventName(eventSelector);
                    eachLog = ifaceLock.parseLog(result.logs[j]);
                } else {
                    throw error;
                }
            }

            let funcStr = eventName + "(";

            for (let k=0; k<eachLog!.args.length; k++) {
                let resultData:string[] = translateData(eachLog!.fragment.inputs[k].type.toString(), eachLog!.args[k].toString());

                if (k == eachLog!.args.length-1) {
                    funcStr = funcStr + resultData[0];
                } else {
                    funcStr = funcStr + resultData[0] + ", ";
                }
            }

            funcStr = funcStr + ")";

            if (isMatch) {
                console.log("\u001b[1;32m" + funcStr + "\u001b[0m");
            } else {
                console.log(funcStr);
            }
        }
    } catch(error) {
        console.log(error);
    }

    console.log("");
}

function consoleTable(input:any) {
    const keys = Object.keys(input[0]);
    let keyLen:any[] = [];

    for (let i=0; i<input.length; i++) {
        for (let j=0; j<keys.length; j++) {
            keyLen[j] = max(keyLen[j], input[i][keys[j]].toString().length, keys[j].length);
        }
    }

    let r = "";
    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + "┌" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┬"; } else { r = r + "┐"; }
    }

    for (let i=0; i<keys.length; i++) {
        if (i == 0) { r = r + '\n' + "│" }
        r = r + " \u001b[1;33m" + keys[i].padEnd(keyLen[i], " ") + "\u001b[0m │";
    }

    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + '\n' + "├" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┼"; } else { r = r + "┤"; }
    }

    for (let k=0; k<input.length; k++) {
        for (let i=0; i<keys.length; i++) {
            if (i == 0) { r = r + '\n' + "│" }
            if (input[k][keys[0]].toString() == "[Ask]") {
                r = r + " \u001b[1;34m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else if (input[k][keys[0]].toString() == "[Bid]") {
                r = r + " \u001b[1;31m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else {
                r = r + " " + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + " │";
            }
        }
        if (k < input.length-1) {
            for (let i=0; i<keys.length; i++) {
                if (i == 0) { r = r + '\n' + "├" }
                for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
                if (i < keys.length-1) { r = r + "┼"; } else { r = r + "┤"; }
            }
        }
    }

    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + '\n' + "└" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┴"; } else { r = r + "┘"; }
    }

    console.log(r);
}

function consoleTable2(input:any) {
    const keys = Object.keys(input[0]);
    let keyLen:any[] = [];

    for (let i=0; i<input.length; i++) {
        for (let j=0; j<keys.length; j++) {
            keyLen[j] = max(keyLen[j], input[i][keys[j]].toString().length, keys[j].length);
        }
    }

    let r = "";
    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + "┌" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┬"; } else { r = r + "┐"; }
    }

    for (let i=0; i<keys.length; i++) {
        if (i == 0) { r = r + '\n' + "│" }
        r = r + " \u001b[1;33m" + keys[i].padEnd(keyLen[i], " ") + "\u001b[0m │";
    }

    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + '\n' + "├" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┼"; } else { r = r + "┤"; }
    }

    for (let k=0; k<input.length; k++) {
        for (let i=0; i<keys.length; i++) {
            if (i == 0) { r = r + '\n' + "│" }
            if (keys[i] == "cumQty" && input[k][keys[i]] != 0) {
                r = r + " \u001b[1;31m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else if (keys[i] == "leavesQty" && input[k][keys[i]] != 0 && input[k][keys[4]].toString() != "Canceled" && input[k][keys[4]].toString() != "Replaced") {
                r = r + " \u001b[1;34m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else if (keys[i] == "side" && input[k][keys[i]].toString() == "Buy") {
                r = r + " \u001b[1;31m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else if (keys[i] == "side" && input[k][keys[i]].toString() == "Sell") {
                r = r + " \u001b[1;34m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else {
                r = r + " " + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + " │";
            }
        }
        if (k < input.length-1) {
            for (let i=0; i<keys.length; i++) {
                if (i == 0) { r = r + '\n' + "├" }
                for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
                if (i < keys.length-1) { r = r + "┼"; } else { r = r + "┤"; }
            }
        }
    }

    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + '\n' + "└" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┴"; } else { r = r + "┘"; }
    }

    console.log(r);
}

function max(a:number, b:number, c:number) {
    if (a > b) {
        if (a > c) {
            return a;
        } else {
            return c;
        }
    } else {
        if (b > c) {
            return b;
        } else {
            return c;
        }
    }
}