import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { toBytes, printEvent, printReceiptEvent } from "./common/common";

import { Whitelist } from "../typechain-types/contracts/utils/whitelist/Whitelist";
import { CurrencyToken } from "../typechain-types/contracts/token/currency/CurrencyToken";
import { STOBeacon } from "../typechain-types/contracts/proxy/beacon/STOBeacon";

// Logic Contract
import { SecurityToken_V1 } from "../typechain-types/contracts/token/security/upgradeable/v1/SecurityToken_V1";
import { STOMatching_V1 } from "../typechain-types/contracts/matching/upgradeable/v1/STOMatching_V1";
import { Gateway_V1 } from "../typechain-types/contracts/gateway/upgradeable/v1/Gateway_V1";


let whitelist:Whitelist;
let currencyToken:CurrencyToken;
let stoBeacon:STOBeacon;

// Logic
let stoV1:SecurityToken_V1;
let matchingV1:STOMatching_V1;
let gatewayV1:Gateway_V1;

// Proxy
let stoMatching:STOMatching_V1;
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

describe("Contract Deployment", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        console.log("\n[Contract Deployment]");

        // 1. Whitelist 배포
        const factoryWhitelist = await ethers.getContractFactory("Whitelist", {signer: deployer});
        whitelist = await factoryWhitelist.connect(deployer).deploy();
        await whitelist.waitForDeployment();
        console.log("Whitelist: " + whitelist.target);

        // 2. CurrencyToken 배포
        const factoryCurrencyToken = await ethers.getContractFactory("CurrencyToken", {signer: deployer});
        currencyToken = await factoryCurrencyToken.connect(deployer).deploy();
        await currencyToken.waitForDeployment();
        console.log("Currency: " + currencyToken.target);

        // 3. SecurityToken_V1 배포
        const factorySecurityToken = await ethers.getContractFactory("SecurityToken_V1", {signer: deployer});
        stoV1 = await factorySecurityToken.connect(deployer).deploy("STO v1.0");
        await stoV1.waitForDeployment();

        // 4. STOBeacon 배포 (implementation address)
        const factoryStoBeacon = await ethers.getContractFactory("STOBeacon", {signer: deployer});
        stoBeacon = await factoryStoBeacon.connect(deployer).deploy(stoV1, deployer, deployer);
        await stoBeacon.waitForDeployment();

        console.log("STO Beacon: " + stoBeacon.target);
        console.log("STO Logic: " + stoV1.target);
        console.log("STO Version: " + await stoV1.getVersion());

        // 5. STOMatching_V1 배포
        const factoryStoMatching = await ethers.getContractFactory("STOMatching_V1", {signer: deployer});
        matchingV1 = await factoryStoMatching.connect(deployer).deploy("STO Matching Engine v1.0");
        await matchingV1.waitForDeployment();

        // 6-1. (STOMatching proxy) STOProxy 배포
        const factoryStoMatchingProxy = await ethers.getContractFactory("STOProxy", {signer: deployer});
        const matchingProxy = await factoryStoMatchingProxy.connect(deployer).deploy(matchingV1, "0x");
        await matchingProxy.waitForDeployment();

        // 6-2. (STOMatching proxy) initialize(currencyToken)
        stoMatching = await ethers.getContractAt("STOMatching_V1", matchingProxy.target.toString());
        await (await stoMatching.connect(deployer).initialize(currencyToken)).wait();

        console.log("STO Matching Proxy: " + stoMatching.target);
        console.log("STO Matching Logic: " + await stoMatching.getImplementation());
        console.log("STO Matching Version: " + await stoMatching.getVersion());

        // 7. Gateway_V1 배포
        const factoryGateway = await ethers.getContractFactory("Gateway_V1", {signer: deployer});
        gatewayV1 = await factoryGateway.connect(deployer).deploy("Gateway v1.0");
        await gatewayV1.waitForDeployment();

        // 8-1. (Gateway proxy) STOProxy 배포
        const factoryGatewayProxy = await ethers.getContractFactory("STOProxy", {signer: deployer});
        const gatewayProxy = await factoryGatewayProxy.connect(deployer).deploy(gatewayV1, "0x");
        await gatewayProxy.waitForDeployment();

        // 8-2. (Gateway proxy) initialize(stoBeacon, stoMatching, currencyToken)
        gw = await ethers.getContractAt("Gateway_V1", gatewayProxy.target.toString());
        await (await gw.connect(deployer).initialize(stoBeacon, stoMatching, whitelist)).wait();

        console.log("Gateway Proxy: " + gw.target);
        console.log("Gateway Logic: " +  await gw.getImplementation());
        console.log("Gateway Version: " +  await gw.getVersion());
    });

    it("Whitelist add account", async function() {
        console.log("\n[Whitelist Accounts]");

        for (let i=0; i<user.length; i++) {
            await (await gw.connect(deployer).addAccount(toBytes(user[i][0]), toBytes(user[i][1]), user[i][2])).wait();
            const [accountStatus, accountAddress] = await gw.getAccountAddress(toBytes(user[i][0]), toBytes(user[i][1]));
            console.log("ittNo: " + user[i][0] + ", acntNo: " + user[i][1] + ", status(address): " + accountStatus + "(" + accountAddress + ")");
        }
    });

    // it("Gateway test", async function() {
    //     console.log("\n[Gateway TokenRegister/TokenQueryInfo]");

    //     receipt = await (await gw.connect(deployer).tokenRegister(toBytes("KRTEST889901"))).wait();

    //     await printReceiptEvent(receipt?.hash, abiPathList, true);
        
    // });
});