import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { toBytes, printEvent, printReceiptEvent, loadAbi } from "../common/common";

// New Gateway Logic Contract
import { Gateway_V1_02 } from "../../typechain-types";

const gatewayProxyAddress = "0x1FB8c2BA3bee2b5Df4310e032ddF108Cf0f5ff6e";
const gwContractName = "Gateway_V1_02";
let gw:Gateway_V1_02;


let deployer:HardhatEthersSigner;
let receipt;

describe("TokenRegister", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        gw = await ethers.getContractAt(gwContractName, gatewayProxyAddress);
        loadAbi();
    });

    it("Gateway tokenRegister", async function() {
        // receipt = await (await gw.tokenRegister(toBytes("KRTESTAAAA02"), {gasLimit: 0x1fffffffffffff})).wait();
        // console.log(receipt?.hash);
        // await printReceiptEvent(receipt?.hash, false);
        await printReceiptEvent("0xae4e9d1fbcee17aedaff1c1b116005317df54b3c88e09ee2700972f3ed01f93f", false);
    });

    // it("Gateway tokenQueryInfo", async function() {
    //     console.log(await gw.tokenQueryInfo(toBytes("KRTESTAAAA02")));
    // });
});