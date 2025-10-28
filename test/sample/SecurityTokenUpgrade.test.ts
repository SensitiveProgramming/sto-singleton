import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { loadAbi, printReceiptEvent, toBytes, printAbi, printAllAbi } from "../common/common";
import { STOBeacon } from "../../typechain-types";

// New Gateway Logic Contract
import { SecurityToken_V1_01 } from "../../typechain-types";

const beaconAddress = "0xae44A0bDcc8fa979b108d7aBA3BD36fb69A6247A";
const newVersionName = "STO v1.01";
const newContractName = "SecurityToken_V1_01";
// const newContractPath = "\\contracts\\token\\security\\upgradeable\\v1.01\\SecurityToken_V1_01.sol";
let beacon:STOBeacon;

let deployer:HardhatEthersSigner;
let receipt;

describe("GatewayUpgrade", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        beacon = await ethers.getContractAt("STOBeacon", beaconAddress);
        loadAbi();
    });

    it("SecurityToken Upgrade", async function() {
        const oldAddress = await beacon.implementation();

        console.log("\nUpgrading SecurityToken to \"" + newVersionName + "\" ...");
        const factoryStoLogic = await ethers.getContractFactory(newContractName, {signer: deployer});
        const stoNewLogic = await factoryStoLogic.connect(deployer).deploy(newVersionName);
        await stoNewLogic.waitForDeployment();
        receipt = await (await beacon.upgradeTo(stoNewLogic.target)).wait();

        console.log("SecurityToken Logic upgrade from [" + oldAddress.toString() + "] to [" + await beacon.implementation() + "]");
        console.log("New SecurityToken Version: " + await stoNewLogic.getVersion());

        await printReceiptEvent(receipt?.hash, false);
    });

    it("SecurityToken Upgrade", async function() {
        const oldAddress = await beacon.implementation();

        console.log("\nUpgrading SecurityToken to \"" + newVersionName + "\" ...");
        const factoryStoLogic = await ethers.getContractFactory(newContractName, {signer: deployer});
        const stoNewLogic = await factoryStoLogic.connect(deployer).deploy(newVersionName);
        await stoNewLogic.waitForDeployment();
        receipt = await (await beacon.upgradeTo(stoNewLogic.target)).wait();

        console.log("SecurityToken Logic upgrade from [" + oldAddress.toString() + "] to [" + await beacon.implementation() + "]");
        console.log("New SecurityToken Version: " + await stoNewLogic.getVersion());

        await printReceiptEvent(receipt?.hash, false);
    });
});