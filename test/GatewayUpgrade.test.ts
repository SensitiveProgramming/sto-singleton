import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { GatewayUpgradeable } from "../typechain-types/contracts/gateway/GatewayUpgradeable";

let gwProxyAddress = "0x0Fbc69182Cb0fB2d4259a69EB6Ca97dc6ad5Be93";
let gw:GatewayUpgradeable;
let deployer:HardhatEthersSigner;
let receipt;

describe("Gateway Test", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        gw = await ethers.getContractAt("GatewayUpgradeable", gwProxyAddress);
    });

    it("Gateway Upgrade", async function() {
        const beforeVersion = await gw.getVersion();
        const beforeAddress = await gw.getImplementation();
        const afterVersion = "Gateway v1.11";

        console.log("\nUpgrading Gateway from \"" + beforeVersion + "\" to \"" + afterVersion + "\" ...");
        const factoryGwLogic = await ethers.getContractFactory("GatewayUpgradeable", {signer: deployer});
        const gwNewLogic = await factoryGwLogic.connect(deployer).deploy(afterVersion.toString());
        await gwNewLogic.waitForDeployment();
        await (await gw.connect(deployer).upgradeToAndCall(gwNewLogic.target, "0x")).wait();

        console.log("Gateway Implementation upgrade from [" + beforeAddress.toString() + "] to [" + await gw.getImplementation() + "]");
    });
});

function toBytes(data:string) {
    return ethers.encodeBytes32String(data);
}