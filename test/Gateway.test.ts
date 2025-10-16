import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { GatewayUpgradeable } from "../typechain-types/contracts/gateway/GatewayUpgradeable";
import { GatewayProxy } from "../typechain-types/contracts/gateway/GatewayProxy";

const ctAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const stAddress = "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853";
const matchingAddress = "0x0165878A594ca255338adfa4d48449f69242Eb8F";

// let ct:CurrencyToken;
// let st:SecurityToken;
let gw:GatewayUpgradeable;
let gwLogicV1:GatewayUpgradeable;
let gwProxy:GatewayProxy;
// let matchingLogicV2:STOMatching_v2;
// let matching:STOMatching_v1 | STOMatching_v2;

let deployer:HardhatEthersSigner;
let receipt;

describe("Matching 단위 테스트", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        // Gateway Logic 컨트랙트 배포
        const factoryGwLogic = await ethers.getContractFactory("GatewayUpgradeable", {signer: deployer});
        gwLogicV1 = await factoryGwLogic.connect(deployer).deploy("Gateway v1.0");
        await gwLogicV1.waitForDeployment();

        // Gateway Proxy 컨트랙트 배포
        const factoryGwProxy = await ethers.getContractFactory("GatewayProxy", {signer: deployer});
        gwProxy = await factoryGwProxy.connect(deployer).deploy(gwLogicV1.target);
        await gwProxy.waitForDeployment();
    });

    it("Gateway test", async function() {
        // Proxy 컨트랙트 주소를 Logic 컨트랙트로 attach (abi: STOGatewayUpgradeable)
        gw = await ethers.getContractAt("GatewayUpgradeable", gwProxy.target.toString());
        await (await gw.connect(deployer).initialize()).wait();

        console.log("Gateway Proxy: " + gw.target);
        console.log("Gateway Implementation: " + await gw.getImplementation());
        console.log("STO Beacon: " + await gw.getStoBeacon());
        console.log("STO Logic: " + await gw.getStoLogic());
        console.log("STO Matching: " + await gw.getStoMatching());
        console.log("Currency Token: " + await gw.getCurrencyToken());

        // console.log("\nUpgrading from v1.0 to v2.0 ...");
        // await (await gw.connect(deployer).deployNewStoLogic("STO v2.0")).wait();
        // console.log("STO Logic Address: " + await gw.getStoLogic());

        receipt = await (await gw.connect(deployer).tokenRegister(toBytes("KRTEST999901"))).wait();
        // console.log(receipt);
        const childAddress = receipt?.logs[0].address;
        console.log("\nSTO: " + await gw.getStoName(toBytes("KRTEST999901")) + ", " + childAddress);
    });
});

function toBytes(data:string) {
    return ethers.encodeBytes32String(data);
}