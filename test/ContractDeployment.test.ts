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

const userList = [
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

        // 1. Whitelist 배포
        const factoryWhitelist = await ethers.getContractFactory("Whitelist", {signer: deployer});
        whitelist = await factoryWhitelist.connect(deployer).deploy();
        await whitelist.waitForDeployment();

        // 2. CurrencyToken 배포
        const factoryCurrencyToken = await ethers.getContractFactory("CurrencyToken", {signer: deployer});
        currencyToken = await factoryCurrencyToken.connect(deployer).deploy();
        await currencyToken.waitForDeployment();

        // 3. SecurityToken_V1 배포
        const factorySecurityToken = await ethers.getContractFactory("SecurityToken_V1", {signer: deployer});
        stoV1 = await factorySecurityToken.connect(deployer).deploy("STO v1.0");
        await stoV1.waitForDeployment();

        // 4. STOBeacon 배포 (implementation address)
        const factoryStoBeacon = await ethers.getContractFactory("STOBeacon", {signer: deployer});
        stoBeacon = await factoryStoBeacon.connect(deployer).deploy(stoV1, deployer, deployer);
        await stoBeacon.waitForDeployment();

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
        await stoMatching.connect(deployer).initialize(currencyToken);

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
        await gw.connect(deployer).initialize(stoBeacon, stoMatching, whitelist);

        console.log("\n[Contract Deployment]");
        console.log("Whitelist: " + whitelist.target);
        console.log("Currency: " + currencyToken.target);
        console.log("STO Beacon: " + stoBeacon.target);
        console.log("STO Logic: " + stoV1.target);
        console.log("STO Version: " + await stoV1.getVersion());
        console.log("STO Matching Proxy: " + stoMatching.target);
        console.log("STO Matching Logic: " + await stoMatching.getImplementation());
        console.log("STO Matching Version: " + await stoMatching.getVersion());
        console.log("Gateway Proxy: " + gw.target);
        console.log("Gateway Logic: " +  await gw.getImplementation());
        console.log("Gateway Version: " +  await gw.getVersion());
    });

    it("Whitelist add account", async function() {
        console.log("\n[Whitelist Accounts]");

        for (let i=0; i<userList.length; i++) {
            await (await gw.connect(deployer).addAccount(toBytes(userList[i][0]), toBytes(userList[i][1]), userList[i][2])).wait();
            const [accountStatus, accountAddress] = await gw.getAccountAddress(toBytes(userList[i][0]), toBytes(userList[i][1]));
            console.log("ittNo: " + userList[i][0] + ", acntNo: " + userList[i][1] + ", status(address): " + accountStatus + "(" + accountAddress + ")");
        }
    });

    it("Gateway test", async function() {
        console.log("\n[Gateway TokenRegister/TokenQueryInfo]");

        receipt = await (await gw.connect(deployer).tokenRegister(toBytes("KRTEST889901"))).wait();

        await printReceiptEvent(receipt?.hash, abiPathList, true);
        // console.log(receipt?.logs[0].address);
        // console.log(receipt?.logs);
        // printEvent(receipt, ["TokenRegister"]);

        // console.log(receipt?.hash);

        // let result = await ethers.provider.send("eth_getTransactionReceipt", [
        //     receipt?.hash
        // ]);

        // console.log("\u001b[1;34m[eth_getTransactionReceipt]\u001b[0m");
        // console.log(result);

        // console.log(config.paths.artifacts.toString().concat("\\contracts\\matching\\upgradeable\\v1\\STOMatching_V1.sol\\STOMatching_V1.json"));
        
    });

    // it("Gateway test", async function() {
    //     // Proxy 컨트랙트 주소를 Logic 컨트랙트로 attach (abi: STOGatewayUpgradeable)
    //     gw = await ethers.getContractAt("GatewayUpgradeable", gwProxy.target.toString());
    //     await (await gw.connect(deployer).initialize()).wait();

    //     console.log("Gateway Proxy: " + gw.target);
    //     console.log("Gateway Implementation: " + await gw.getImplementation());
    //     console.log("STO Beacon: " + await gw.getStoBeacon());
    //     console.log("STO Logic: " + await gw.getStoLogic());
    //     console.log("STO Matching: " + await gw.getStoMatching());
    //     console.log("Currency Token: " + await gw.getCurrencyToken());

    //     // console.log("\nUpgrading from v1.0 to v2.0 ...");
    //     // await (await gw.connect(deployer).deployNewStoLogic("STO v2.0")).wait();
    //     // console.log("STO Logic Address: " + await gw.getStoLogic());

    //     receipt = await (await gw.connect(deployer).tokenRegister(toBytes("KRTEST999901"))).wait();
    //     // console.log(receipt);
    //     const childAddress = receipt?.logs[0].address;
    //     console.log("\nSTO: " + await gw.getStoName(toBytes("KRTEST999901")) + ", " + childAddress);
    // });
});


// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { ethers } from "hardhat";
// import { GatewayUpgradeable } from "../typechain-types/contracts/gateway/GatewayUpgradeable";
// import { GatewayProxy } from "../typechain-types/contracts/gateway/GatewayProxy";

// const ctAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
// const stAddress = "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853";
// const matchingAddress = "0x0165878A594ca255338adfa4d48449f69242Eb8F";

// // let ct:CurrencyToken;
// // let st:SecurityToken;
// let gw:GatewayUpgradeable;
// let gwLogicV1:GatewayUpgradeable;
// let gwProxy:GatewayProxy;
// // let matchingLogicV2:STOMatching_v2;
// // let matching:STOMatching_v1 | STOMatching_v2;

// let deployer:HardhatEthersSigner;
// let receipt;

// describe("Matching 단위 테스트", async function () {
//     before(async function() {
//         [deployer] = await ethers.getSigners();

//         // Gateway Logic 컨트랙트 배포
//         const factoryGwLogic = await ethers.getContractFactory("GatewayUpgradeable", {signer: deployer});
//         gwLogicV1 = await factoryGwLogic.connect(deployer).deploy("Gateway v1.0");
//         await gwLogicV1.waitForDeployment();

//         // Gateway Proxy 컨트랙트 배포
//         const factoryGwProxy = await ethers.getContractFactory("GatewayProxy", {signer: deployer});
//         gwProxy = await factoryGwProxy.connect(deployer).deploy(gwLogicV1.target);
//         await gwProxy.waitForDeployment();
//     });

//     it("Gateway test", async function() {
//         // Proxy 컨트랙트 주소를 Logic 컨트랙트로 attach (abi: STOGatewayUpgradeable)
//         gw = await ethers.getContractAt("GatewayUpgradeable", gwProxy.target.toString());
//         await (await gw.connect(deployer).initialize()).wait();

//         console.log("Gateway Proxy: " + gw.target);
//         console.log("Gateway Implementation: " + await gw.getImplementation());
//         console.log("STO Beacon: " + await gw.getStoBeacon());
//         console.log("STO Logic: " + await gw.getStoLogic());
//         console.log("STO Matching: " + await gw.getStoMatching());
//         console.log("Currency Token: " + await gw.getCurrencyToken());

//         // console.log("\nUpgrading from v1.0 to v2.0 ...");
//         // await (await gw.connect(deployer).deployNewStoLogic("STO v2.0")).wait();
//         // console.log("STO Logic Address: " + await gw.getStoLogic());

//         receipt = await (await gw.connect(deployer).tokenRegister(toBytes("KRTEST999901"))).wait();
//         // console.log(receipt);
//         const childAddress = receipt?.logs[0].address;
//         console.log("\nSTO: " + await gw.getStoName(toBytes("KRTEST999901")) + ", " + childAddress);
//     });
// });

// function toBytes(data:string) {
//     return ethers.encodeBytes32String(data);
// }