import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { toBytes, printEvent, printReceiptEvent } from "../common/common";
import { setContractAddress, printOrderBook, printQuoteList, printAllOrders, printQuoteOrderList } from "../common/matching_test";

import { CurrencyToken } from "../../typechain-types/contracts/token/currency/CurrencyToken";
// import { STOBeacon } from "../typechain-types/contracts/proxy/beacon/STOBeacon";


// Logic Contract
// import { SecurityToken_V1 } from "../typechain-types/contracts/token/security/upgradeable/v1/SecurityToken_V1";
import { STOMatching_V1 } from "../../typechain-types/contracts/matching/upgradeable/v1/STOMatching_V1";
import { Gateway_V1_02 } from "../../typechain-types/contracts/gateway/upgradeable/v1.02/Gateway_V1_02";


// const stoBeaconAddress = "";
// const sampleStoProxyAddress = ""



const currencyTokenAddress = "0xDde4389979c7670347dF9053f0ca503bC6D23E8D";
const stoMatchingProxyAddress = "0x92B4671b0Ae3729fb062740078113f5968F68DCf";
const gatewayProxyAddress = "0x1FB8c2BA3bee2b5Df4310e032ddF108Cf0f5ff6e";

// let stoBeacon:STOBeacon;
// let sampleSto:SecurityToken_V2;
let currencyToken:CurrencyToken;
let matching:STOMatching_V1;
let gw:Gateway_V1_02;


let deployer:HardhatEthersSigner;
let receipt;

let tmpOrderId:bigint = BigInt(0);
let lastOrderId:bigint = BigInt(6);
function getOrderId() {
    tmpOrderId++;
    return (tmpOrderId + lastOrderId);
}

// abi paths
const abiPathList = [
    config.paths.artifacts.concat("\\contracts\\utils\\whitelist\\Whitelist.sol\\Whitelist.json"),
    config.paths.artifacts.concat("\\contracts\\token\\currency\\CurrencyToken.sol\\CurrencyToken.json"),
    config.paths.artifacts.concat("\\contracts\\gateway\\upgradeable\\v1\\Gateway_V1_02.sol\\Gateway_V1_02.json"),
    config.paths.artifacts.concat("\\contracts\\matching\\upgradeable\\v1\\STOMatching_V1.sol\\STOMatching_V1.json"),
    config.paths.artifacts.concat("\\contracts\\token\\security\\upgradeable\\v1\\SecurityToken_V1.sol\\SecurityToken_V1.json"),
    // config.paths.artifacts.concat("\\contracts\\proxy\\STOProxy.sol\\STOProxy.json"),
    // config.paths.artifacts.concat("\\contracts\\proxy\\STOSelectableProxy.sol\\STOSelectableProxy.json"),
]

const user = [
    ["500000", "KR134-00000001", "0xbc1396a5b9901a551698f21ab6b98545d2e6061a"],
    ["500000", "KR134-77777772", "0x77369d4997639ec3322a98feacfb88bafd512dc1"],
    ["500000", "KR134-77777773", "0x628e59c70465f18ed427ed870340d1e2eb10541b"],
    ["500000", "KR134-88888844", "0x82e90e923459fd74bba664df8f128102652c688b"],
    ["500000", "KR134-88888886", "0x80679a6e51886fda4794f131bb015e035b092db7"],
    ["500000", "KR134-88888887", "0x816c03f18fdd1e41e942f4ee49dfb82962092beb"],
    ["500000", "KR134-88888888", "0xb5c5913f8615e57f40262e3a3e70dd95726abdd0"],
    ["500000", "KR134-88888889", "0x4c71a058afbcfa7de56fcdfbb4f86f5b73ec0a55"],
];

const isuNo = toBytes("KRTEST889901");

describe("MatchingBuySell", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        // stoBeacon = await ethers.getContractAt("STOBeacon", stoBeaconAddress);
        // sampleSto = await ethers.getContractAt("SecurityToken_V2", sampleStoProxyAddress); 
        // matching = await ethers.getContractAt("STOMatching_V2", stoMatchingProxyAddress);
        currencyToken = await ethers.getContractAt("CurrencyToken", currencyTokenAddress);
        matching = await ethers.getContractAt("STOMatching_V1", stoMatchingProxyAddress);
        gw = await ethers.getContractAt("Gateway_V1_02", gatewayProxyAddress);
        setContractAddress(currencyTokenAddress, "0x6996C832E89FB88F9810AaDc5eE4fd323cEDC420", stoMatchingProxyAddress);
    });

    it("Gateway matching sample", async function() {
        // receipt = await (await gw.balanceStockIn(
        //     toBytes(user[2][0]), 
        //     toBytes(user[2][1]), 
        //     toBytes("02"), 
        //     toBytes("Y"), 
        //     isuNo, 
        //     2000, 
        //     toBytes("00"), 
        //     toBytes("11"), 
        //     toBytes("111"), 
        //     toBytes("")
        // )).wait();
        // await printReceiptEvent(receipt?.hash, abiPathList, false);

        // receipt = await (await currencyToken.connect(deployer).issue(user[3][2], 20000000)).wait();
        // await printReceiptEvent(receipt?.hash, abiPathList, false);

        // receipt = await (await gw.placeBuyOrder(getOrderId(), toBytes(user[3][0]), toBytes(user[3][1]), isuNo, 18000, 100)).wait();
        // await printReceiptEvent(receipt?.hash, abiPathList, false);

        // receipt = await (await gw.placeSellOrder(getOrderId(), toBytes(user[2][0]), toBytes(user[2][1]), isuNo, 18000, 50)).wait();
        // await printReceiptEvent(receipt?.hash, abiPathList, false);
    });

    it("Matching Info", async function() {
        // await printOrderBook();
        // await printQuoteList();

        // console.log(await gw.getOrderBookInfo(isuNo));
        // console.log("");
        // console.log(await gw.getAllQuoteListInfo(isuNo));
        // console.log("");
        // console.log(await gw.getQuoteOrdersInfo(isuNo, 20000));
        // console.log("");
        // console.log(await gw.getQuoteOrdersInfo(isuNo, 18000));
        // console.log("");
        // console.log(await gw.getAllQuoteListInfo(isuNo));
        // console.log("");
        // console.log(await gw.getOrderInfo(1));
        // console.log("");
        // console.log(await gw.getOrderInfo(2));
        // console.log("");
        // console.log(await gw.getOrderInfo(3));
        // console.log("");
        console.log(await gw.getOrderInfo(7));
    });
});