import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { toBytes, printEvent, printReceiptEvent } from "../common/common";

// import { STOBeacon } from "../typechain-types/contracts/proxy/beacon/STOBeacon";


// Logic Contract
// import { SecurityToken_V1 } from "../typechain-types/contracts/token/security/upgradeable/v1/SecurityToken_V1";
// import { STOMatching_V1 } from "../typechain-types/contracts/matching/upgradeable/v1/STOMatching_V1";
import { Gateway_V1 } from "../../typechain-types/contracts/gateway/upgradeable/v1/Gateway_V1";


// const stoBeaconAddress = "";
// const sampleStoProxyAddress = ""
// const stoMatchingProxyAddress = "";
const gatewayProxyAddress = "0x1FB8c2BA3bee2b5Df4310e032ddF108Cf0f5ff6e";

// let stoBeacon:STOBeacon;
// let sampleSto:SecurityToken_V2;
// let matching:STOMatching_V2;
let gw:Gateway_V1;

let deployer:HardhatEthersSigner;
let receipt;

// abi paths
const abiPathList = [
    config.paths.artifacts.concat("\\contracts\\utils\\whitelist\\Whitelist.sol\\Whitelist.json"),
    config.paths.artifacts.concat("\\contracts\\token\\currency\\CurrencyToken.sol\\CurrencyToken.json"),
    config.paths.artifacts.concat("\\contracts\\gateway\\upgradeable\\v1\\Gateway_V1.sol\\Gateway_V1.json"),
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

describe("BalanceStockIn", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        // stoBeacon = await ethers.getContractAt("STOBeacon", stoBeaconAddress);
        // sampleSto = await ethers.getContractAt("SecurityToken_V2", sampleStoProxyAddress); 
        // matching = await ethers.getContractAt("STOMatching_V2", stoMatchingProxyAddress); 
        gw = await ethers.getContractAt("Gateway_V1", gatewayProxyAddress);
    });

    it("Gateway balanceStockIn", async function() {
        receipt = await (await gw.balanceStockIn(
            toBytes(user[0][0]), 
            toBytes(user[0][1]), 
            toBytes("02"), 
            toBytes("Y"), 
            isuNo, 
            1000, 
            toBytes("00"), 
            toBytes("11"), 
            toBytes("111"), 
            toBytes("")
        )).wait();
        await printReceiptEvent(receipt?.hash, false);
    });

    it("Gateway accountQueryBalanceByIsuNo", async function() {
        console.log(await gw.accountQueryBalanceByIsuNo(toBytes(user[0][0]), isuNo, toBytes(user[0][1])));
    });
});