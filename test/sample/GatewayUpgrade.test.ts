import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { loadAbi, printReceiptEvent, toBytes, printAbi } from "../common/common";

// New Gateway Logic Contract
import { Gateway_V1_04 } from "../../typechain-types";

const gatewayProxyAddress = "0x1FB8c2BA3bee2b5Df4310e032ddF108Cf0f5ff6e";
const newVersionName = "Gateway v1.04";
const newContractName = "Gateway_V1_04";
const newContractPath = "\\contracts\\gateway\\upgradeable\\v1.04\\Gateway_V1_04.sol";
let gw:Gateway_V1_04;


let deployer:HardhatEthersSigner;
let receipt;

describe("GatewayUpgrade", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        gw = await ethers.getContractAt(newContractName, gatewayProxyAddress);
        loadAbi();
    });

    // it("Gateway Upgrade", async function() {
    //     const oldVersion = await gw.getVersion();
    //     const oldAddress = await gw.getImplementation();

    //     console.log("\nUpgrading Gateway from \"" + oldVersion + "\" to \"" + newVersionName + "\" ...");
    //     const factoryGwLogic = await ethers.getContractFactory(newContractName, {signer: deployer});
    //     const gwNewLogic = await factoryGwLogic.connect(deployer).deploy(newVersionName);
    //     await gwNewLogic.waitForDeployment();
    //     receipt = await (await gw.connect(deployer).upgradeToAndCall(gwNewLogic.target, "0x")).wait();

    //     console.log("Gateway Logic upgrade from [" + oldAddress.toString() + "] to [" + await gw.getImplementation() + "]");
    //     console.log("New Gateway Version: " + await gw.getVersion());

    //     await printReceiptEvent(receipt?.hash, false);
    // });

    // it("Gateway reinitialize", async function() {
    //     const oldVersion = await gw.getVersion();
    //     const oldAddress = await gw.getImplementation();

    //     console.log("\nGate reinitialize ...");
    //     receipt = await (await gw.connect(deployer).reinitialize("0xDde4389979c7670347dF9053f0ca503bC6D23E8D")).wait();

    //     await printReceiptEvent(receipt?.hash, false);
    // });

    // it("Get currency balance test", async function() {
    //     console.log(await gw.getCurrencyBalanceByAddress("0x77369d4997639eC3322a98FeACfb88bafD512dC1"));
    //     console.log(await gw.getCurrencyBalanceByAccount(toBytes("500000"), toBytes("KR134-77777772")));
    // });

    it("Gateway ABI", async function() {
        printAbi(config.paths.artifacts.concat("\\contracts\\gateway\\upgradeable\\v1.04\\Gateway_V1_04.sol\\Gateway_V1_04.json"), false);


        // let result = await ethers.provider.getLogs({
        //     // address: "0x92B4671b0Ae3729fb062740078113f5968F68DCf",
        //     fromBlock: 0x1A8BE0,
        //     toBlock: 0x1A9B21,
        //     address: "0x92B4671b0Ae3729fb062740078113f5968F68DCf",
        //     topics: ["0x15af9e6eeca95c39cd8b080d69ca6b16837f4f1298d457b9ba6712f62691dfa5"],
        // });

        // // let result = await ethers.provider.getBlockNumber();

        // console.log(result.length);
    });
});