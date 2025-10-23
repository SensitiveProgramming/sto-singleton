import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { printReceiptEvent } from "../common/common";

// New Gateway Logic Contract
import { Gateway_V1_02 } from "../../typechain-types";

const gatewayProxyAddress = "0x1FB8c2BA3bee2b5Df4310e032ddF108Cf0f5ff6e";
const newVersionName = "Gateway v1.02";
const newContractName = "Gateway_V1_02";
const newContractPath = "\\contracts\\gateway\\upgradeable\\v1.02\\Gateway_V1_02.sol";
let gw:Gateway_V1_02;


let deployer:HardhatEthersSigner;
let receipt;

// abi paths
const abiPathList = [
    config.paths.artifacts.concat(newContractPath + "\\" + newContractName + ".json"),
]

describe("GatewayUpgrade", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        gw = await ethers.getContractAt(newContractName, gatewayProxyAddress);
    });

    it("Gateway Upgrade", async function() {
        const oldVersion = await gw.getVersion();
        const oldAddress = await gw.getImplementation();

        console.log("\nUpgrading Gateway from \"" + oldVersion + "\" to \"" + newVersionName + "\" ...");
        const factoryGwLogic = await ethers.getContractFactory(newContractName, {signer: deployer});
        const gwNewLogic = await factoryGwLogic.connect(deployer).deploy(newVersionName);
        await gwNewLogic.waitForDeployment();
        receipt = await (await gw.connect(deployer).upgradeToAndCall(gwNewLogic.target, "0x")).wait();

        console.log("Gateway Logic upgrade from [" + oldAddress.toString() + "] to [" + await gw.getImplementation() + "]");
        console.log("Gateway New Version: " + await gw.getVersion());
        console.log(abiPathList[0].toString());

        await printReceiptEvent(receipt?.hash, abiPathList, false);
    });
});