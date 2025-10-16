// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library DoublyLinkedList {
    struct Uint256List {
        mapping (uint256 => bool) exist;
        mapping (uint256 => uint256) prev;
        mapping (uint256 => uint256) next;
        uint256 head;
        uint256 tail;
        uint256 length;
    }

    error DllDuplicateNode(uint256 node);
    error DllNodeNotFound(uint256 node);
    error DllNodeCannotBeZero();

    function exists(Uint256List storage list, uint256 node) internal view returns (bool) {
        return list.exist[node];
    }

    function length(Uint256List storage list) internal view returns (uint256) {
        return list.length;
    }

    function getNode(Uint256List storage list, uint256 node) internal view returns (bool, uint256, uint256) {
        return (list.exist[node], list.prev[node], list.next[node]);
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

    function _ifDuplicated(Uint256List storage list, uint256 node) private view {
        if (exists(list, node)) {
            revert DllDuplicateNode(node);
        }
    }

    function _ifNotExists(Uint256List storage list, uint256 node) private view {
        if (!exists(list, node)) {
            revert DllNodeNotFound(node);
        }
    }

    function _ifZeroNode(uint256 node) private pure {
        if (node == 0) {
            revert DllNodeCannotBeZero();
        }
    }
}