import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { toBytes, printEvent, printReceiptEvent, loadAbi, printAbi } from "../common/common";

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
        printAbi();
    });

    it("Gateway tokenRegister", async function() {
        // receipt = await (await gw.tokenRegister(toBytes("KRTESTAAAA03"), {gasLimit: 0x1fffffffffffff})).wait().catch(e => e.receipt || {status:0});
        // await printReceiptEvent(receipt?.hash, true);
        // await printReceiptEvent("0x979f8dfedc40d9412a680567ca88dccdd6ab275510824ad6fe63a7de9eed8126", true);
    });

    // it("Gateway tokenQueryInfo", async function() {
    //     console.log(await gw.tokenQueryInfo(toBytes("KRTESTAAAA03")));
    // });
});