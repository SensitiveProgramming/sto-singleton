// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./matching/STOMatchingStruct.sol";

struct Test {
    address sampleAddress;
    uint256 sampleUint;
}

contract KeccakTest {
    constructor() {
    }

    // function tupleTest(Order memory order, Order[] memory orders) external view virtual returns (bytes32) {
    //     return bytes32(msg.data);
    // }

    function tupleTest(Test memory test1, Test[] memory test2) external view virtual returns (bytes32 keccak, Test memory testOut1, Test[] memory testOut2) {
        keccak = bytes32(msg.data);
        testOut1 = test1;
        testOut2 = test2;
    }

    function tupleTest2(Test memory test1, Test[] memory test2, Test[][] memory test3) external view virtual returns (bytes32 keccak, Test memory testOut1, Test[] memory testOut2, Test[][] memory testOut3) {
        keccak = bytes32(msg.data);
        testOut1 = test1;
        testOut2 = test2;
        testOut3 = test3;
    }

    function bytes32Test(bytes32 t1, bytes32[] memory t2) external view virtual returns (bytes32 keccak, bytes32 tOut1, bytes32[] memory tOut2) {
        keccak = bytes32(msg.data);
        tOut1 = t1;
        tOut2 = t2;
    }

    function bytes32Test2(bytes32 t1, bytes32[] memory t2, bytes32[][] memory t3) external view virtual returns (bytes32 keccak, bytes32 tOut1, bytes32[] memory tOut2, bytes32[][] memory tOut3) {
        keccak = bytes32(msg.data);
        tOut1 = t1;
        tOut2 = t2;
        tOut3 = t3;
    }
}