import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { loadAbi, printReceiptEvent, toBytes, printAbi } from "./common/common";

// New Gateway Logic Contract
import { KeccakTest } from "../typechain-types";

let kt:KeccakTest;


let deployer:HardhatEthersSigner;
let receipt;

describe("GatewayUpgrade", async function () {
    before(async function() {
        [deployer] = await ethers.getSigners();

        const factoryTest = await ethers.getContractFactory("KeccakTest", {signer: deployer});
        kt = await factoryTest.connect(deployer).deploy();
        await kt.waitForDeployment();
    });

    it("Abi Test", async function() {
        printAbi(config.paths.artifacts.concat("\\contracts\\KeccakTest.sol\\KeccakTest.json"), true);

        console.log(await kt.tupleTest(
            {
                sampleAddress: ethers.ZeroAddress,
                sampleUint: 100
            },
            [
                {
                    sampleAddress: ethers.ZeroAddress,
                    sampleUint: 200
                }, {
                    sampleAddress: ethers.ZeroAddress,
                    sampleUint: 300
                }
            ]
        ));

        console.log(await kt.tupleTest2(
            {
                sampleAddress: ethers.ZeroAddress,
                sampleUint: 100
            },
            [
                {
                    sampleAddress: ethers.ZeroAddress,
                    sampleUint: 200
                }, {
                    sampleAddress: ethers.ZeroAddress,
                    sampleUint: 300
                }
            ],
            [
                [
                    {
                        sampleAddress: ethers.ZeroAddress,
                        sampleUint: 400
                    }, {
                        sampleAddress: ethers.ZeroAddress,
                        sampleUint: 500
                    }
                ],
                [
                    {
                        sampleAddress: ethers.ZeroAddress,
                        sampleUint: 600
                    }, {
                        sampleAddress: ethers.ZeroAddress,
                        sampleUint: 700
                    }
                ]
            ]
        ));

        console.log(await kt.bytes32Test(
            toBytes("aaaa"),
            [
                toBytes("bbbb"), toBytes("cccc")
            ]
        ));

        console.log(await kt.bytes32Test2(
            toBytes("aaaa"),
            [
                toBytes("bbbb"), toBytes("cccc")
            ],
            [
                [
                    toBytes("dddd"), toBytes("eeee")
                ],[
                    toBytes("ffff"), toBytes("gggg")
                ]
            ]
        ));
    });
});