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

    function sampleTest0(bool a) external view virtual returns (bool a1) {
        a1 = a;
    }

    function sampleTest1(string memory a) external view virtual returns (string memory a1) {
        a1 = a;
    }

    function sampleTest2(bytes memory a) external view virtual returns (bytes memory a1) {
        a1 = a;
    }

    function sampleTest3(uint256 a, uint256 b) external view virtual returns (uint256 a1, uint256 b1) {
        a1 = a;
        b1 = b;
    }

    function sampleTest4(uint256 a, bytes32 b, address c) external view virtual returns (bytes memory keccak, uint256 a1, bytes32 b1, address c1) {
        keccak = msg.data;
        a1 = a;
        b1 = b;
        c1 = c;
    }

    function tupleTest0(Test memory test1) external view virtual returns (bytes memory keccak, Test memory testOut1) {
        keccak = msg.data;
        testOut1 = test1;
    }

    function tupleTest01(Test[] memory test1) external view virtual returns (bytes memory keccak, Test[] memory testOut1) {
        keccak = msg.data;
        testOut1 = test1;
    }

    function tupleTest(Test memory test1, Test[] memory test2) external view virtual returns (bytes memory keccak, Test memory testOut1, Test[] memory testOut2) {
        keccak = msg.data;
        testOut1 = test1;
        testOut2 = test2;
    }

    function tupleTest2(Test memory test1, Test[] memory test2, Test[][] memory test3) external view virtual returns (bytes memory keccak, Test memory testOut1, Test[] memory testOut2, Test[][] memory testOut3) {
        keccak = msg.data;
        testOut1 = test1;
        testOut2 = test2;
        testOut3 = test3;
    }

    function bytes32Test(bytes32 t1, bytes32[] memory t2) external view virtual returns (bytes memory keccak, bytes32 tOut1, bytes32[] memory tOut2) {
        keccak = msg.data;
        tOut1 = t1;
        tOut2 = t2;
    }

    function bytes32Test2(bytes32 t1, bytes32[] memory t2, bytes32[][] memory t3) external view virtual returns (bytes memory keccak, bytes32 tOut1, bytes32[] memory tOut2, bytes32[][] memory tOut3) {
        keccak = msg.data;
        tOut1 = t1;
        tOut2 = t2;
        tOut3 = t3;
    }
}