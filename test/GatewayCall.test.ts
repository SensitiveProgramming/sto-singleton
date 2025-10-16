import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { GatewayUpgradeable } from "../typechain-types/contracts/gateway/GatewayUpgradeable";

let gwProxyAddress = "0x0Fbc69182Cb0fB2d4259a69EB6Ca97dc6ad5Be93";
let gw:GatewayUpgradeable;
let deployer:HardhatEthersSigner;
let receipt;

describe("Matching 단위 테스트", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        gw = await ethers.getContractAt("GatewayUpgradeable", gwProxyAddress);
    });

    it("Gateway test", async function() {
        console.log("\n[Contract Address]");
        console.log("Gateway Proxy: " + gw.target);
        console.log("Gateway Implementation: " + await gw.getImplementation());
        console.log("STO Beacon: " + await gw.getStoBeacon());
        console.log("STO Logic: " + await gw.getStoLogic());
        console.log("STO Matching: " + await gw.getStoMatching());
        console.log("Currency Token: " + await gw.getCurrencyToken());

        const sampleSto = "KRTEST999901";
        console.log("\nname: " + await gw.getStoName(toBytes(sampleSto)));
        console.log("symbol: " + await gw.getStoSymbol(toBytes(sampleSto)));
        console.log("address: " + await gw.getStoAddress(toBytes(sampleSto)));

        console.log(await gw.tokenQueryInfo(toBytes(sampleSto)));
    });
});

function toBytes(data:string) {
    return ethers.encodeBytes32String(data);
}