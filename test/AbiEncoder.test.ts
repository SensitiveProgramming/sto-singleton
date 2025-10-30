import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, config } from "hardhat";
import { loadAbi, printReceiptEvent, toBytes, printAbi, getAbi } from "./common/common";

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
        // console.log(getAbi(config.paths.artifacts.concat("\\contracts\\KeccakTest.sol\\KeccakTest.json")));
        const iface = new ethers.Interface(getAbi(config.paths.artifacts.concat("\\contracts\\KeccakTest.sol\\KeccakTest.json")));
        
        const encoded = iface.encodeFunctionData("tupleTest2", [
            {
                sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
                sampleUint: 100
            },
            [
                {
                    sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
                    sampleUint: 200
                }, {
                    sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
                    sampleUint: 300
                }
            ],
            [
                [
                    {
                        sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
                        sampleUint: 400
                    }, {
                        sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
                        sampleUint: 500
                    }
                ],
                [
                    {
                        sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
                        sampleUint: 600
                    }, {
                        sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
                        sampleUint: 700
                    }
                ]
            ]
        ]);
        console.log(encoded);

        // const encoded = iface.encodeFunctionData("tupleTest", [
        //     [
        //         "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
        //         "100"
        //     ],
        //     [
        //         [
        //             "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
        //             "200"
        //         ],
        //         [
        //             "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
        //             "300"
        //         ],
        //     ]
        // ]);
        // console.log(encoded);

        // const encoded = iface.encodeFunctionData("tupleTest01", [
        //     [
        //         [
        //             "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
        //             "200"
        //         ],
        //         [
        //             "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
        //             "300"
        //         ],
        //     ]
        // ]);
        // console.log(encoded);

        // const sig = Web3.providers. .eth.abi.encodeFunctionCall(
        //     {
        //         name: "myMethod",
        //         type: "function",
        //         inputs: [
        //         {
        //             type: "uint256",
        //             name: "myNumber",
        //         },
        //         {
        //             type: "string",
        //             name: "myString",
        //         },
        //         ],
        //     },
        //     ["10", "Hello!"]
        // );

        // printAbi(config.paths.artifacts.concat("\\contracts\\KeccakTest.sol\\KeccakTest.json"), true);

        // console.log(await kt.sampleTest4(10, toBytes("KRTEST889901"), "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412"));


        // console.log(await kt.tupleTest0(
        //     {
        //         sampleAddress: "0xC00d13BaB974EFbe61BDf343ffbAFf7eA4909412",
        //         sampleUint: 100
        //     }
        // ));

        // console.log(await kt.tupleTest2(
        //     {
        //         sampleAddress: ethers.ZeroAddress,
        //         sampleUint: 100
        //     },
        //     [
        //         {
        //             sampleAddress: ethers.ZeroAddress,
        //             sampleUint: 200
        //         }, {
        //             sampleAddress: ethers.ZeroAddress,
        //             sampleUint: 300
        //         }
        //     ],
        //     [
        //         [
        //             {
        //                 sampleAddress: ethers.ZeroAddress,
        //                 sampleUint: 400
        //             }, {
        //                 sampleAddress: ethers.ZeroAddress,
        //                 sampleUint: 500
        //             }
        //         ],
        //         [
        //             {
        //                 sampleAddress: ethers.ZeroAddress,
        //                 sampleUint: 600
        //             }, {
        //                 sampleAddress: ethers.ZeroAddress,
        //                 sampleUint: 700
        //             }
        //         ]
        //     ]
        // ));

        // console.log(await kt.bytes32Test(
        //     toBytes("aaaa"),
        //     [
        //         toBytes("bbbb"), toBytes("cccc")
        //     ]
        // ));

        // console.log(await kt.bytes32Test2(
        //     toBytes("aaaa"),
        //     [
        //         toBytes("bbbb"), toBytes("cccc")
        //     ],
        //     [
        //         [
        //             toBytes("dddd"), toBytes("eeee")
        //         ],[
        //             toBytes("ffff"), toBytes("gggg")
        //         ]
        //     ]
        // ));
    });
});