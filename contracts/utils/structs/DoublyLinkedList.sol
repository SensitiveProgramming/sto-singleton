// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library DoublyLinkedList {
    struct AddressList {
        mapping (address => bool) exist;
        mapping (address => address) prev;
        mapping (address => address) next;
        address head;
        address tail;
        uint256 length;
    }

    struct Uint256List {
        mapping (uint256 => bool) exist;
        mapping (uint256 => uint256) prev;
        mapping (uint256 => uint256) next;
        uint256 head;
        uint256 tail;
        uint256 length;
    }

    struct Bytes32List {
        mapping (bytes32 => bool) exist;
        mapping (bytes32 => bytes32) prev;
        mapping (bytes32 => bytes32) next;
        bytes32 head;
        bytes32 tail;
        uint256 length;
    }

    error DuplicateAddressNode(address node);
    error AddressNodeNotFound(address node);
    error AddressNodeCannotBeZero();

    error DuplicateUint256Node(uint256 node);
    error Uint256NodeNotFound(uint256 node);
    error Uint256NodeCannotBeZero();

    error DuplicateBytes32Node(bytes32 node);
    error Bytes32NodeNotFound(bytes32 node);
    error Bytes32NodeCannotBeNull();


    function exists(AddressList storage list, address node) internal view returns (bool) {
        return list.exist[node];
    }

    function exists(Uint256List storage list, uint256 node) internal view returns (bool) {
        return list.exist[node];
    }

    function exists(Bytes32List storage list, bytes32 node) internal view returns (bool) {
        return list.exist[node];
    }

    function length(AddressList storage list) internal view returns (uint256) {
        return list.length;
    }

    function length(Uint256List storage list) internal view returns (uint256) {
        return list.length;
    }

    function length(Bytes32List storage list) internal view returns (uint256) {
        return list.length;
    }

    function getNode(AddressList storage list, address node) internal view returns (bool, address, address) {
        return (list.exist[node], list.prev[node], list.next[node]);
    }

    function getNode(Uint256List storage list, uint256 node) internal view returns (bool, uint256, uint256) {
        return (list.exist[node], list.prev[node], list.next[node]);
    }

    function getNode(Bytes32List storage list, bytes32 node) internal view returns (bool, bytes32, bytes32) {
        return (list.exist[node], list.prev[node], list.next[node]);
    }

    function insert(AddressList storage list, address node) internal {
        _ifDuplicated(list, node);
        _ifZeroNode(node);

        if (list.length == 0) {
            list.head = node;
        } else {
            list.next[list.tail] = node;
            list.prev[node] = list.tail;
        }

        list.tail = node;
        list.exist[node] = true;
        list.length++;
    }

    function insert(Uint256List storage list, uint256 node) internal {
        _ifDuplicated(list, node);
        _ifZeroNode(node);

        if (list.length == 0) {
            list.head = node;
        } else {
            list.next[list.tail] = node;
            list.prev[node] = list.tail;
        }

        list.tail = node;
        list.exist[node] = true;
        list.length++;
    }

    function insert(Bytes32List storage list, bytes32 node) internal {
        _ifDuplicated(list, node);
        _ifZeroNode(node);

        if (list.length == 0) {
            list.head = node;
        } else {
            list.next[list.tail] = node;
            list.prev[node] = list.tail;
        }

        list.tail = node;
        list.exist[node] = true;
        list.length++;
    }

    function remove(AddressList storage list, address node) internal {
        _ifNotExists(list, node);
        _ifZeroNode(node);

        if (node == list.tail) {
            list.tail = list.prev[node];
        }

        if (node == list.head) {
            list.head = list.next[node];
        }

        list.prev[list.next[node]] = list.prev[node];
        list.next[list.prev[node]] = list.next[node];
        list.exist[node] = false;
        list.prev[node] = address(0);
        list.next[node] = address(0);
        list.length--;
    }

    function remove(Uint256List storage list, uint256 node) internal {
        _ifNotExists(list, node);
        _ifZeroNode(node);

        if (node == list.tail) {
            list.tail = list.prev[node];
        }

        if (node == list.head) {
            list.head = list.next[node];
        }

        list.prev[list.next[node]] = list.prev[node];
        list.next[list.prev[node]] = list.next[node];
        list.exist[node] = false;
        list.prev[node] = 0;
        list.next[node] = 0;
        list.length--;
    }

    function remove(Bytes32List storage list, bytes32 node) internal {
        _ifNotExists(list, node);
        _ifZeroNode(node);

        if (node == list.tail) {
            list.tail = list.prev[node];
        }

        if (node == list.head) {
            list.head = list.next[node];
        }

        list.prev[list.next[node]] = list.prev[node];
        list.next[list.prev[node]] = list.next[node];
        list.exist[node] = false;
        list.prev[node] = bytes32(bytes(""));
        list.next[node] = bytes32(bytes(""));
        list.length--;
    }

    function getList(AddressList storage list, address start, uint256 maxSize) internal view returns (address[] memory, address) {
        _ifNotExists(list, start);
        
        address[] memory nodes = new address[](maxSize);
        address current = start;
        uint256 returnLength;

        if (start == address(0)) {
            current = list.head;
        } else {
            current = start;
        }

        while (current != address(0) && returnLength < maxSize) {
            nodes[returnLength] = current;
            current = list.next[current];
            returnLength++;
        }

        address[] memory returnAddresses = new address[](returnLength);
        for (uint256 i=0; i<returnLength; i++) {
            returnAddresses[i] = nodes[i];
        }

        return (returnAddresses, current);
    }

    function getList(Uint256List storage list, uint256 start, uint256 maxSize) internal view returns (uint256[] memory, uint256) {
        _ifNotExists(list, start);
        
        uint256[] memory nodes = new uint256[](maxSize);
        uint256 current = start;
        uint256 returnLength;

        if (start == 0) {
            current = list.head;
        } else {
            current = start;
        }

        while (current != 0 && returnLength < maxSize) {
            nodes[returnLength] = current;
            current = list.next[current];
            returnLength++;
        }

        uint256[] memory returnAddresses = new uint256[](returnLength);
        for (uint256 i=0; i<returnLength; i++) {
            returnAddresses[i] = nodes[i];
        }

        return (returnAddresses, current);
    }

    function getList(Bytes32List storage list, bytes32 start, uint256 maxSize) internal view returns (bytes32[] memory, bytes32) {
        _ifNotExists(list, start);
        
        bytes32[] memory nodes = new bytes32[](maxSize);
        bytes32 current = start;
        uint256 returnLength;

        if (start == 0) {
            current = list.head;
        } else {
            current = start;
        }

        while (current != bytes32(bytes("")) && returnLength < maxSize) {
            nodes[returnLength] = current;
            current = list.next[current];
            returnLength++;
        }

        bytes32[] memory returnAddresses = new bytes32[](returnLength);
        for (uint256 i=0; i<returnLength; i++) {
            returnAddresses[i] = nodes[i];
        }

        return (returnAddresses, current);
    }

    function getAllList(AddressList storage list) internal view returns (address[] memory) {
        uint256 returnLength = length(list);
        address[] memory nodes = new address[](returnLength);
        address current = list.head;

        for (uint256 i=0; i<returnLength; i++) {
            nodes[i] = current;
            current = list.next[current];
        }

        return (nodes);
    }

    function getAllList(Uint256List storage list) internal view returns (uint256[] memory) {
        uint256 returnLength = length(list);
        uint256[] memory nodes = new uint256[](returnLength);
        uint256 current = list.head;

        for (uint256 i=0; i<returnLength; i++) {
            nodes[i] = current;
            current = list.next[current];
        }

        return (nodes);
    }

    function getAllList(Bytes32List storage list) internal view returns (bytes32[] memory) {
        uint256 returnLength = length(list);
        bytes32[] memory nodes = new bytes32[](returnLength);
        bytes32 current = list.head;

        for (uint256 i=0; i<returnLength; i++) {
            nodes[i] = current;
            current = list.next[current];
        }

        return (nodes);
    }

    function _ifDuplicated(AddressList storage list, address node) private view {
        if (exists(list, node)) {
            revert DuplicateAddressNode(node);
        }
    }

    function _ifNotExists(AddressList storage list, address node) private view {
        if (!exists(list, node)) {
            revert AddressNodeNotFound(node);
        }
    }

    function _ifZeroNode(address node) private pure {
        if (node == address(0)) {
            revert AddressNodeCannotBeZero();
        }
    }

    function _ifDuplicated(Uint256List storage list, uint256 node) private view {
        if (exists(list, node)) {
            revert DuplicateUint256Node(node);
        }
    }

    function _ifNotExists(Uint256List storage list, uint256 node) private view {
        if (!exists(list, node)) {
            revert Uint256NodeNotFound(node);
        }
    }

    function _ifZeroNode(uint256 node) private pure {
        if (node == 0) {
            revert Uint256NodeCannotBeZero();
        }
    }

    function _ifDuplicated(Bytes32List storage list, bytes32 node) private view {
        if (exists(list, node)) {
            revert DuplicateBytes32Node(node);
        }
    }

    function _ifNotExists(Bytes32List storage list, bytes32 node) private view {
        if (!exists(list, node)) {
            revert Bytes32NodeNotFound(node);
        }
    }

    function _ifZeroNode(bytes32 node) private pure {
        if (node == bytes32(bytes(""))) {
            revert Bytes32NodeCannotBeNull();
        }
    }
}