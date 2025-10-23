// import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
// import { ethers, config } from "hardhat";
// // import { toBytes, printEvent, printReceiptEvent } from "../common/common";

// // Logic Contract
// import { Gateway_V1_02 } from "../../typechain-types/contracts/gateway/upgradeable/v1.02/Gateway_V1_02";

// const gatewayProxyAddress = "0x1fb8c2ba3bee2b5df4310e032ddf108cf0f5ff6e";
// const newVersion = "Gateway v1.02";
// let gw:Gateway_V1_02;


// let deployer:HardhatEthersSigner;
// let receipt;

// // abi paths
// const abiPathList = [
//     config.paths.artifacts.concat("\\contracts\\utils\\whitelist\\Whitelist.sol\\Whitelist.json"),
//     config.paths.artifacts.concat("\\contracts\\token\\currency\\CurrencyToken.sol\\CurrencyToken.json"),
//     config.paths.artifacts.concat("\\contracts\\gateway\\upgradeable\\v1.02\\Gateway_V1_02.sol\\Gateway_V1_02.json"),
//     config.paths.artifacts.concat("\\contracts\\matching\\upgradeable\\v1\\STOMatching_V1.sol\\STOMatching_V1.json"),
//     config.paths.artifacts.concat("\\contracts\\token\\security\\upgradeable\\v1\\SecurityToken_V1.sol\\SecurityToken_V1.json"),
//     // config.paths.artifacts.concat("\\contracts\\proxy\\STOProxy.sol\\STOProxy.json"),
//     // config.paths.artifacts.concat("\\contracts\\proxy\\STOSelectableProxy.sol\\STOSelectableProxy.json"),
// ]

// describe("GatewayUpgrade", async function () {
//     before(async function() {
//         [deployer] = await ethers.getSigners();

//         gw = await ethers.getContractAt("Gateway_V1_02", gatewayProxyAddress);
//     });

//     it("Gateway Upgrade", async function() {
//         const beforeVersion = await gw.getVersion();
//         const beforeAddress = await gw.getImplementation();
        

//         console.log("\nUpgrading Gateway from \"" + beforeVersion + "\" to \"" + newVersion + "\" ...");
//         const factoryGwLogic = await ethers.getContractFactory("Gateway_V1_02", {signer: deployer});
//         const gwNewLogic = await factoryGwLogic.connect(deployer).deploy(newVersion.toString());
//         await gwNewLogic.waitForDeployment();
//         await (await gw.connect(deployer).upgradeToAndCall(gwNewLogic.target, "0x")).wait();

//         console.log("Gateway Logic upgrade from [" + beforeAddress.toString() + "] to [" + await gw.getImplementation() + "]");
//         console.log("Gateway New Version: " + await gw.getVersion());
//     });

//     // it("STO Logic Upgrade", async function() {
//     //     const beforeAddress = await sampleSto.getImplementation();
//     //     const beforeVersion = await sampleSto.getVersion();
//     //     const afterVersion = "STO v2.0";

//     //     console.log("\nUpgrading STO from \"" + beforeVersion + "\" to \"" + afterVersion + "\" ...");
//     //     const factoryStoLogic = await ethers.getContractFactory("SecurityToken_V2", {signer: deployer});
//     //     const stoNewLogic = await factoryStoLogic.connect(deployer).deploy(afterVersion.toString());
//     //     await stoNewLogic.waitForDeployment();
//     //     await (await stoBeacon.connect(deployer).upgradeTo(stoNewLogic.target)).wait();

//     //     console.log("STO Logic upgrade from [" + beforeAddress.toString() + "] to [" + await sampleSto.getImplementation() + "]");
//     //     console.log("STO New Version: " + await sampleSto.getVersion());
//     // });

//     // it("STO Matching Upgrade", async function() {
//     //     const beforeVersion = await matching.getVersion();
//     //     const beforeAddress = await matching.getImplementation();
//     //     const afterVersion = "STO Matching Engine v2.0";

//     //     console.log("\nUpgrading STO Matching from \"" + beforeVersion + "\" to \"" + afterVersion + "\" ...");
//     //     const factoryMatchingLogic = await ethers.getContractFactory("STOMatching_V2", {signer: deployer});
//     //     const matchingNewLogic = await factoryMatchingLogic.connect(deployer).deploy(afterVersion.toString());
//     //     await matchingNewLogic.waitForDeployment();
//     //     await (await matching.connect(deployer).upgradeToAndCall(matchingNewLogic.target, "0x")).wait();

//     //     console.log("STO Matching Logic upgrade from [" + beforeAddress.toString() + "] to [" + await matching.getImplementation() + "]");
//     //     console.log("STO Matching New Version: " + await matching.getVersion());
//     // });
// });