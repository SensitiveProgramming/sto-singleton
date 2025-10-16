// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract AvlTree2 {
    struct Node {
        uint256 value;
        uint256 left;
        uint256 right;
        uint256 height;
    }

    /**
     * @dev 토큰 호가창 조회를 원할하게 하기 위한 avl tree 관리용
     */
    mapping (address => mapping (uint256 => Node)) private _node;
    mapping (address => uint256) private _root;
    mapping (address => uint256) private _size;

    error ZeroValue();
    error NonExistentValue(uint256 value);
    error AlreadyExistentValue(uint256 value);

    function _exists(address token, uint256 value) internal view returns (bool) {
        _checkZeroValue(value);

        if (_node[token][value].value > 0) {
            return true;
        } else {
            return false;
        }
    }

    function _insert(address token, uint256 value) internal {
        _checkZeroValue(value);
        _checkAlreadyExistentValue(token, value);

        _insertNode(token, _root[token], value);
        _size[token]++;
    }

    function _remove(address token, uint256 value) internal {
        _checkZeroValue(value);
        _checkNonExistentValue(token, value);

        _removeNode(token, _root[token], value);
        _size[token]--;
    }

    function _insertNode(address token, uint256 root, uint256 value) private returns (uint256) {
        if (root == 0) {
            _node[token][value] = Node({
                value: value,
                left: 0,
                right: 0,
                height: 1
            });
            return value;
        }

        if (value < _node[token][root].value) {
            _node[token][root].left = _insertNode(token, _node[token][root].left, value);
        } else {
            _node[token][root].right = _insertNode(token, _node[token][root].right, value);
        }

        return _balance(token, root);
    }

    function _removeNode(address token, uint256 root, uint256 value) private returns (uint256) {
        uint256 tmp;

        if (root == 0) {
            return root;
        }

        if (_node[token][root].value == value) {
            if (_node[token][root].left == 0 || _node[token][root].right == 0) {
                if (_node[token][root].left == 0) {
                    tmp = _node[token][root].right;
                } else {
                    tmp = _node[token][root].left;
                }
                _node[token][root] = _node[token][0];
                return tmp;
            } else {
                for (tmp = _node[token][root].right; _node[token][tmp].left != 0; tmp = _node[token][tmp].left) {}
                _node[token][root].value = _node[token][tmp].value;
                _node[token][tmp] = _node[token][0];
                _node[token][root].right = _removeNode(token, _node[token][root].right, _node[token][tmp].value);
                return _balance(token, root);
            }
        }

        if (value < _node[token][root].value) {
            _node[token][root].left = _removeNode(token, _node[token][root].left, value);
        } else {
            _node[token][root].right = _removeNode(token, _node[token][root].right, value);
        }

        return _balance(token, root);
    }

    function _balance(address token, uint256 root) private returns (uint256) {
        if (root > 0) {
            _node[token][root].height = 1 + _max(_node[token][_node[token][root].left].height, _node[token][_node[token][root].right].height);
        }

        if (_node[token][_node[token][root].left].height > _node[token][_node[token][root].right].height + 1) {
            if (_node[token][_node[token][_node[token][root].left].right].height > _node[token][_node[token][_node[token][root].left].left].height) {
                _node[token][root].left = _rotateRight(token, _node[token][root].left);
            }
            return _rotateLeft(token, root);
        } else if (_node[token][_node[token][root].right].height > _node[token][_node[token][root].left].height + 1) {
            if (_node[token][_node[token][_node[token][root].right].left].height > _node[token][_node[token][_node[token][root].right].right].height) {
                _node[token][root].right = _rotateLeft(token, _node[token][root].right);
            }
            return _rotateRight(token, root);
        }

        return root;
    }

    function _rotateLeft(address token, uint256 root) private returns (uint256) {
        uint256 tmp = _node[token][root].left;
        _node[token][root].left = _node[token][tmp].right;
        _node[token][tmp].right = root;

        if (root > 0) {
            _node[token][root].height = 1 + _max(_node[token][_node[token][root].left].height, _node[token][_node[token][root].right].height);
        }

        if (tmp > 0) {
            _node[token][tmp].height = 1 + _max(_node[token][_node[token][tmp].left].height, _node[token][_node[token][tmp].right].height);
        }

        return tmp;
    }

    function _rotateRight(address token, uint256 root) private returns (uint256) {
        uint256 tmp = _node[token][root].right;
        _node[token][root].right = _node[token][tmp].left;
        _node[token][tmp].left = root;

        if (root > 0) {
            _node[token][root].height = 1 + _max(_node[token][_node[token][root].left].height, _node[token][_node[token][root].right].height);
        }

        if (tmp > 0) {
            _node[token][tmp].height = 1 + _max(_node[token][_node[token][tmp].left].height, _node[token][_node[token][tmp].right].height);
        }

        return tmp;
    }

    function _max(uint256 x, uint256 y) private pure returns (uint256) {
        if (x > y) {
            return x;
        } else {
            return y;
        }
    } 

    function _checkZeroValue(uint256 value) private pure {
        if (value == 0) {
            revert ZeroValue();
        }
    }

    function _checkAlreadyExistentValue(address token, uint256 value) private view {
        if (_node[token][value].value == value) {
            revert AlreadyExistentValue(value);
        }
    }

    function _checkNonExistentValue(address token, uint256 value) private view {
        if (_node[token][value].value == 0) {
            revert NonExistentValue(value);
        }
    }

    function getNode(address token, uint256 value) external view returns (uint256, uint256, uint256, uint256) {
        return (
            _node[token][value].value, 
            _node[token][value].left, 
            _node[token][value].right, 
            _node[token][value].height
        );
    }

    function getRoot(address token) external view returns (uint256) {
        return _root[token];
    }
}