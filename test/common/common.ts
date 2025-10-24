import { ethers, config } from "hardhat";
import { Console } from "console";
import { Transform } from "stream";
import * as fs from "fs";
import * as path from "path";

interface Data {
    type:string;
    name:string;
    dataDecoded:string;
    dataEncoded:string;
}

// abi paths
let abi:any[] = [];

export function translateData(type:string, data:string) {
    try {
        if (type.includes("uint")) {
            return [data, ethers.toBeHex(data, 32).substring(2)];
        } else if (type == "bytes") {
            let resultStr = ethers.toUtf8String(data).replace(/\x00/g, ' ');
            if (resultStr.length == 0) {
                return ["(null)", "(null)"];
            } else {
                return [resultStr, data.substring(2)];
            }
        } else if (type.includes("bytes")) {
            let resultStr = ethers.decodeBytes32String(data);
            if (resultStr.length == 0) {
                return ["", data.substring(2)];
            } else {
                return [resultStr, data.substring(2)];
            }
        } else if (type == "address") {
            return [data, ethers.zeroPadValue(data, 32).substring(2)];
        } else if (type == "string") {
            return [data, ethers.hexlify(ethers.toUtf8Bytes(data)).substring(2)];
        } else {
            return ["(undefined type)", "(undefined type)"];
        }
    } catch(error) {
        if (error instanceof Error) {
            if (error.message.includes("invalid bytes32 string") || error.message.includes("invalid BytesLike value")) {
                return ["", data.substring(2)];
            }
        }

        throw error;
    }
}

export function toBytes(data:string) {
    return ethers.encodeBytes32String(data);
}

export function printEvent(receipt:any, eventName:any[]) {
    let logs = receipt?.logs;
    let isPrint = false;

    console.log(logs);

    for (const event of logs) {
        for (let i=0; i<eventName.length; i++) {
            if (event.fragment && event.fragment.name === eventName[i]) {
                // console.log(event.interface);
                // _event = event.args;
                let consoleStr = eventName[i] + "(" + event.args[0];
                for (let j=1; j<event.args.length; j++) {
                    if (event.args[j].toString().includes(",")) {
                        consoleStr = consoleStr + ", [" + event.args[j] + "]";
                    } else {
                        consoleStr = consoleStr + ", " + event.args[j];
                    }
                }
                consoleStr = consoleStr + ")";
                console.log(consoleStr);
                isPrint = true;
            }
        }
    }

    if (!isPrint) {
        console.log("null");
    }
}

export function printAllEvent(receipt:any) {
    let logs = receipt?.logs;
    // let _event = null;
    let isPrint = false;

    for (const event of logs) {
        if (event.fragment) {
            let consoleStr = event.fragment.name + "(" + event.args[0];
            for (let j=1; j<event.args.length; j++) {
                if (event.args[j].toString().includes(",")) {
                    consoleStr = consoleStr + ", [" + event.args[j] + "]";
                } else {
                    consoleStr = consoleStr + ", " + event.args[j];
                }
            }
            consoleStr = consoleStr + ")";
            console.log(consoleStr);
            isPrint = true;
        }
    }

    if (!isPrint) {
        console.log("null");
    }

    console.log("");
}

// export async function printReceiptEvent(txHash:any, abiPaths:any[], printJson:boolean) {
//     let result;

//     try {
//         result = await ethers.provider.send("eth_getTransactionReceipt", [
//             txHash
//         ]);

//         if (printJson) {
//             console.log("\n\u001b[1;34m[eth_getTransactionReceipt]\u001b[0m");
//             console.log(result);
//         }

//         if (result.revertReason != null) {
//             console.log("\n\u001b[1;31m[Error 정보]\u001b[0m");

//             let inAbiList:boolean = false;

//             for (let k=0; k<abiPaths.length; k++) {
//                 const dir = abiPaths[k];
//                 const file = fs.readFileSync(dir, 'utf-8');
//                 const json = JSON.parse(file);

//                 const contractName = json.contractName;
//                 const iface = new ethers.Interface(json.abi);
//                 const parseError = iface.parseError(result.revertReason);

//                 if (parseError == null) {
//                     continue;
//                 } else {
//                     let tbData:Data[] = [];

//                     if (parseError.selector == "0x08c379a0") {
//                         inAbiList = true;
//                         console.log("오류: " + parseError.signature);
//                         let resultData:string[] = translateData(parseError.fragment.inputs[0].type.toString(), parseError.args[0].toString());
//                         let tb:Data = {
//                             type: parseError.fragment.inputs[0].type.toString(),
//                             name: "    ",
//                             dataDecoded: resultData[0],
//                             dataEncoded: resultData[1],
//                         }
//                         tbData.push(tb);
//                     } else {
//                         console.log("커스텀오류: " + parseError.signature);
//                         for (let k=0; k<parseError.fragment.inputs.length; k++) {
//                             let resultData:string[] = translateData(parseError.fragment.inputs[k].type.toString(), parseError.args[k].toString());
//                             let tb:Data = {
//                                 type: parseError.fragment.inputs[k].type.toString(),
//                                 name: parseError.fragment.inputs[k].name.toString(),
//                                 dataDecoded: resultData[0],
//                                 dataEncoded: resultData[1],
//                             }
//                             tbData.push(tb);
//                         }
//                     }

//                     if (tbData.length > 0) {
//                         consoleTable(tbData);
//                     }
//                 }

//                 break;
//             }

//             if (!inAbiList) {
//                 console.log("알수없는오류: " + result.revertReason);
//             }
//         } else {
//             console.log("\n\u001b[1;32m[Event 정보]\u001b[0m");
//             for (let j=0; j<result.logs.length; j++) {
//                 let inAbiList:boolean = false;

//                 for (let k=0; k<abiPaths.length; k++) {
//                     const dir = abiPaths[k];
//                     const file = fs.readFileSync(dir, 'utf-8');
//                     const json = JSON.parse(file);

//                     const contractName = json.contractName;
//                     const iface = new ethers.Interface(json.abi);
//                     const eventSelector = result.logs[j].topics[0];
//                     let eventName;

//                     try {
//                         eventName = iface.getEventName(eventSelector);
//                         inAbiList = true;
//                     } catch(error) {
//                         if (error instanceof TypeError) {
//                             if (error.message.includes("no matching event")) {
//                                 continue;
//                             }
//                         } else {
//                             throw error;
//                         }
//                     }

//                     console.log("logIndex: " + j + ", event: " + eventName + ", contract: " + result.logs[j].address);
//                     const eachLog = iface.parseLog(result.logs[j]);

//                     let tbData:Data[] = [];
//                     for (let k=0; k<eachLog!.args.length; k++) {
//                         let resultData:string[] = translateData(eachLog!.fragment.inputs[k].type.toString(), eachLog!.args[k].toString());
//                         let tb:Data = {
//                             type: eachLog!.fragment.inputs[k].type.toString(),
//                             name: eachLog!.fragment.inputs[k].name.toString(),
//                             dataDecoded: resultData[0],
//                             dataEncoded: resultData[1],
//                         }
//                         tbData.push(tb);
//                     }

//                     consoleTable(tbData);
//                     console.log("");
//                     break;
//                 }

//                 if (!inAbiList) {
//                     console.log("logIndex: " + j + ", event: " + result.logs[j].topics[0]);
//                 }
//             }
//         }
//     } catch(error) {
//         console.log(error);
//     }
// }

export async function printReceiptEvent(txHash:any, printJson:boolean) {
    let result;

    try {
        result = await ethers.provider.send("eth_getTransactionReceipt", [
            txHash
        ]);

        if (printJson) {
            console.log("\n\u001b[1;34m[eth_getTransactionReceipt]\u001b[0m");
            console.log(result);
        }

        if (result.revertReason != null) {
            console.log("\n\u001b[1;31m[Error 정보]\u001b[0m");

            let inAbiList:boolean = false;

            for (let k=0; k<abi.length; k++) {
                const iface = new ethers.Interface(abi[k]);
                const parseError = iface.parseError(result.revertReason);

                if (parseError == null) {
                    continue;
                } else {
                    let tbData:Data[] = [];

                    if (parseError.selector == "0x08c379a0") {
                        inAbiList = true;
                        console.log("오류: " + parseError.signature);
                        let resultData:string[] = translateData(parseError.fragment.inputs[0].type.toString(), parseError.args[0].toString());
                        let tb:Data = {
                            type: parseError.fragment.inputs[0].type.toString(),
                            name: "    ",
                            dataDecoded: resultData[0],
                            dataEncoded: resultData[1],
                        }
                        tbData.push(tb);
                    } else {
                        console.log("커스텀오류: " + parseError.signature);
                        for (let k=0; k<parseError.fragment.inputs.length; k++) {
                            let resultData:string[] = translateData(parseError.fragment.inputs[k].type.toString(), parseError.args[k].toString());
                            let tb:Data = {
                                type: parseError.fragment.inputs[k].type.toString(),
                                name: parseError.fragment.inputs[k].name.toString(),
                                dataDecoded: resultData[0],
                                dataEncoded: resultData[1],
                            }
                            tbData.push(tb);
                        }
                    }

                    if (tbData.length > 0) {
                        consoleTable(tbData);
                    }
                }

                break;
            }

            if (!inAbiList) {
                console.log("알수없는오류: " + result.revertReason);
            }
        } else {
            console.log("\n\u001b[1;32m[Event 정보]\u001b[0m");
            for (let j=0; j<result.logs.length; j++) {
                let inAbiList:boolean = false;

                for (let k=0; k<abi.length; k++) {
                    const iface = new ethers.Interface(abi[k]);
                    const eventSelector = result.logs[j].topics[0];
                    let eventName;

                    try {
                        eventName = iface.getEventName(eventSelector);
                        inAbiList = true;
                    } catch(error) {
                        if (error instanceof TypeError) {
                            if (error.message.includes("no matching event")) {
                                continue;
                            }
                        } else {
                            throw error;
                        }
                    }

                    console.log("logIndex: " + j + ", event: " + eventName + ", contract: " + result.logs[j].address);
                    const eachLog = iface.parseLog(result.logs[j]);

                    let tbData:Data[] = [];
                    for (let k=0; k<eachLog!.args.length; k++) {
                        let resultData:string[] = translateData(eachLog!.fragment.inputs[k].type.toString(), eachLog!.args[k].toString());
                        let tb:Data = {
                            type: eachLog!.fragment.inputs[k].type.toString(),
                            name: eachLog!.fragment.inputs[k].name.toString(),
                            dataDecoded: resultData[0],
                            dataEncoded: resultData[1],
                        }
                        tbData.push(tb);
                    }

                    consoleTable(tbData);
                    console.log("");
                    break;
                }

                if (!inAbiList) {
                    console.log("logIndex: " + j + ", event: " + result.logs[j].topics[0]);
                }
            }
        }
    } catch(error) {
        console.log(error);
    }
}

// export function consoleTable(input:any) {
//     const ts = new Transform({ transform(chunk, enc, cb) { cb(null, chunk) } });
//     const logger = new Console({ stdout: ts });
//     logger.table(input);
//     const table = (ts.read() || '').toString();
//     let result = '';
//     let r;
//     let row = table.split(/[\r\n]+/);
//     let tmp;

//     for (let i=0; i<row.length; i++) {
//         if (row[i].length == 0) {
//             break;
//         }

//         r = row[i].replace(/[^┬]*┬/, '┌');
//         r = r.replace(/^├─*┼/, '├');
//         r = r.replace(/│[^│]*/, '');
//         r = r.replace(/^└─*┴/, '└');
//         r = r.replace(/'/g, ' ');

//         if (i == 1) {
//             r = r.replace(/│ /g, '│  ');
//             r = r.replace(/ │/g, '│');
//             r = r.replace(/type/g, '\u001b[1;33mtype\u001b[0m');
//             r = r.replace(/name/g, '\u001b[1;33mname\u001b[0m');
//             r = r.replace(/dataDecoded/g, '\u001b[1;33mdataDecoded\u001b[0m');
//             r = r.replace(/dataEncoded/g, '\u001b[1;33mdataEncoded\u001b[0m');
//         }

//         if (i == 0) {
//             result += `${r}`;
//         } else {
//             result += `\n${r}`;
//         }

//         if (i == 2) {
//             tmp = r;
//         }

//         if (i > 2 && i < (row.length-3)) {
//             result = result + '\n' + tmp;
//         }
//     }

//     result = result.replace(/┌─/, '┌');
//     result = result.replace(/├─/g, '├');
//     result = result.replace(/└─/, '└');
//     result = result.replace(/─┬─/g, '┬');
//     result = result.replace(/─┼─/g, '┼');
//     result = result.replace(/─┴─/g, '┴');
//     result = result.replace(/─┐/, '┐');
//     result = result.replace(/─┤/g, '┤');
//     result = result.replace(/─┘/, '┘');
//     result = result.replace(/│ /g, '│');
//     result = result.replace(/ │/g, '│');
//     console.log(result);
// }

export function loadAbi() {
    // 1. Whitelist abi loading
    abi.push(getAbi(config.paths.artifacts.concat("\\contracts\\utils\\whitelist\\Whitelist.sol\\Whitelist.json")));

    // 2. CurrencyToken abi loading
    abi.push(getAbi(config.paths.artifacts.concat("\\contracts\\token\\currency\\CurrencyToken.sol\\CurrencyToken.json")));

    // 3. SecurityToken abi loading
    abi.push(getAbi(getRecentUpgradeableFilePath(config.paths.artifacts.concat("\\contracts\\token\\security\\upgradeable"))));

    // 4. STOMatching abi loading
    abi.push(getAbi(getRecentUpgradeableFilePath(config.paths.artifacts.concat("\\contracts\\matching\\upgradeable"))));

    // 5. Gateway abi loading
    abi.push(getAbi(getRecentUpgradeableFilePath(config.paths.artifacts.concat("\\contracts\\gateway\\upgradeable"))));
}

export function printAbi() {
    let functionList = [];
    let eventList = [];
    let errorList = [];
    let map = new Map<string, string>();

    try {
        console.log("\n\u001b[1;34m[Functions]\u001b[0m");
        for (let k=0; k<abi.length; k++) {
            for (let i=0; i<abi[k].length; i++) {
                let funcAbi:string = "";

                if (abi[k][i].type == 'function') {
                    let keccakStr;
                    funcAbi = funcAbi + abi[k][i].name + "(";

                    if (abi[k][i].inputs.length > 0) {
                        funcAbi = funcAbi + abi[k][i].inputs[0].type;

                        for (let j=1; j<abi[k][i].inputs.length; j++) {
                            funcAbi = funcAbi + "," + abi[k][i].inputs[j].type;
                        }
                    }

                    funcAbi = funcAbi + ")";
                    keccakStr = keccak(funcAbi).substring(0, 10);

                    if (abi[k][i].outputs!.length > 0) {
                        funcAbi = funcAbi + " returns (";
                        funcAbi = funcAbi + abi[k][i].outputs[0].type;

                        for (let j=1; j<abi[k][i].outputs!.length; j++) {
                            funcAbi = funcAbi + "," + abi[k][i].outputs![j].type;
                        }

                        funcAbi = funcAbi + ")";
                    }

                    // console.log(keccakStr + " " + funcAbi);

                    if (!map.has(funcAbi)) {
                        map.set(funcAbi, keccakStr);
                        functionList.push(funcAbi);
                    }
                }
            }
        }

        functionList.sort();
        for (let i=0; i<functionList.length; i++) {
            console.log(map.get(functionList[i]) + "|" + functionList[i]);
        }
        map.clear;

        console.log("\n\u001b[1;34m[Events]\u001b[0m");
        for (let k=0; k<abi.length; k++) {
            for (let i=0; i<abi[k].length; i++) {
                let funcAbi:string = "";
                let fullStr:string = "";

                if (abi[k][i].type == 'event') {
                    funcAbi = funcAbi + abi[k][i].name + "(";
                    fullStr = fullStr + abi[k][i].name + "(";

                    if (abi[k][i].inputs.length > 0) {
                        funcAbi = funcAbi + abi[k][i].inputs[0].type;
                        fullStr = fullStr + abi[k][i].inputs[0].type + " " + abi[k][i].inputs[0].name;

                        for (let j=1; j<abi[k][i].inputs.length; j++) {
                            funcAbi = funcAbi + "," + abi[k][i].inputs[j].type;
                            fullStr = fullStr + ", " + abi[k][i].inputs[j].type + " " + abi[k][i].inputs[j].name;
                        }
                    }
                    
                    funcAbi = funcAbi + ")";
                    fullStr = fullStr + ")";
                    // console.log(keccak(funcAbi) + " " + funcAbi);
                    // console.log(keccak(funcAbi) + "|" + fullStr);

                    if (!map.has(fullStr)) {
                        map.set(fullStr, keccak(funcAbi));
                        eventList.push(fullStr);
                    }
                }
            }
        }

        eventList.sort();
        for (let i=0; i<eventList.length; i++) {
            console.log(map.get(eventList[i]) + "|" + eventList[i]);
        }
        map.clear;

        console.log("\n\u001b[1;34m[Errors]\u001b[0m");
        for (let k=0; k<abi.length; k++) {
            for (let i=0; i<abi[k].length; i++) {
                let funcAbi:string = "";
                let fullStr:string = "";

                if (abi[k][i].type == 'error') {
                    // console.log(abi[k][i]);
                    funcAbi = funcAbi + abi[k][i].name + "(";
                    fullStr = fullStr + abi[k][i].name + "(";

                    if (abi[k][i].inputs.length > 0) {
                        funcAbi = funcAbi + abi[k][i].inputs[0].type;
                        fullStr = fullStr + abi[k][i].inputs[0].type + " " + abi[k][i].inputs[0].name;

                        for (let j=1; j<abi[k][i].inputs.length; j++) {
                            funcAbi = funcAbi + "," + abi[k][i].inputs[j].type;
                            fullStr = fullStr + ", " + abi[k][i].inputs[j].type + " " + abi[k][i].inputs[j].name;
                        }
                    }

                    funcAbi = funcAbi + ")";
                    fullStr = fullStr + ")";
                    // console.log(keccak(funcAbi).substring(0, 10) + " " + funcAbi);
                    // console.log(keccak(funcAbi).substring(0, 10) + "|" + fullStr);

                    if (!map.has(fullStr)) {
                        map.set(fullStr, keccak(funcAbi).substring(0, 10));
                        errorList.push(fullStr);
                    }
                }
            }
        }

        errorList.sort();
        for (let i=0; i<errorList.length; i++) {
            console.log(map.get(errorList[i]) + "|" + errorList[i]);
        }
        map.clear;
    } catch(error) {
        console.log("오류 메시지: ");
        if (error instanceof Error) {
            console.log(error.message);
        }
    }
}

export function keccak(data:string) {
    return ethers.keccak256(new TextEncoder().encode(data));
}

function consoleTable(input:any) {
    const keys = Object.keys(input[0]);
    let keyLen:any[] = [];

    for (let i=0; i<input.length; i++) {
        for (let j=0; j<keys.length; j++) {
            keyLen[j] = max(keyLen[j], input[i][keys[j]].toString().length, keys[j].length);
        }
    }

    let r = "";
    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + "┌" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┬"; } else { r = r + "┐"; }
    }

    for (let i=0; i<keys.length; i++) {
        if (i == 0) { r = r + '\n' + "│" }
        r = r + " \u001b[1;33m" + keys[i].padEnd(keyLen[i], " ") + "\u001b[0m │";
    }

    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + '\n' + "├" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┼"; } else { r = r + "┤"; }
    }

    for (let k=0; k<input.length; k++) {
        for (let i=0; i<keys.length; i++) {
            if (i == 0) { r = r + '\n' + "│" }
            if (input[k][keys[0]].toString() == "[Ask]") {
                r = r + " \u001b[1;34m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else if (input[k][keys[0]].toString() == "[Bid]") {
                r = r + " \u001b[1;31m" + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + "\u001b[0m │";
            } else {
                r = r + " " + input[k][keys[i]].toString().padEnd(keyLen[i], " ") + " │";
            }
        }
        if (k < input.length-1) {
            for (let i=0; i<keys.length; i++) {
                if (i == 0) { r = r + '\n' + "├" }
                for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
                if (i < keys.length-1) { r = r + "┼"; } else { r = r + "┤"; }
            }
        }
    }

    for (let i=0; i<keyLen.length; i++) {
        if (i == 0) { r = r + '\n' + "└" }
        for (let j=0; j<keyLen[i]+2; j++) { r = r + "─"; }
        if (i < keys.length-1) { r = r + "┴"; } else { r = r + "┘"; }
    }

    console.log(r);
}

function getRecentUpgradeableFilePath(upgradeablePath:string) {
    let targetPath = upgradeablePath;
    let entries;

    while (true) {
        entries = fs.readdirSync(targetPath);

        if (entries.length > 0) {
            entries.sort();
            targetPath = targetPath + "\\" + entries[entries.length - 1];

            if (fs.statSync(targetPath).isFile()) {
                // console.log(targetPath);
                return targetPath;
            }
        } else {
            break;
        }
    }

    return "";
}

function getAbi(abiFilePath:string) {
    const dir = path.resolve(__dirname, abiFilePath);
    const file = fs.readFileSync(dir, 'utf-8');
    const json = JSON.parse(file);
    return json.abi;
}

function max(a:number, b:number, c:number) {
    if (a > b) {
        if (a > c) {
            return a;
        } else {
            return c;
        }
    } else {
        if (b > c) {
            return b;
        } else {
            return c;
        }
    }
}