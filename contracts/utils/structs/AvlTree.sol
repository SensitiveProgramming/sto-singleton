// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library AvlTree {
    struct Tree {
        uint256 root;
        uint256 size;
        mapping (uint256 => Node) node;
    }

    struct Node {
        uint256 key;
        uint256 parent;
        uint256 left;
        uint256 right;
        uint256 height;
    }

    error ZeroKeyNotAllowed();
    error DuplicateKey(uint256 key);
    error NonExistentKey(uint256 key);

    function root(Tree storage tree) internal view returns (uint256) {
        return tree.root;
    }

    function size(Tree storage tree) internal view returns (uint256) {
        return tree.size;
    }

    function exists(Tree storage tree, uint256 key) internal view returns (bool) {
        return (tree.node[key].key > 0);
    }

    function getSmallest(Tree storage tree) internal view returns (uint256) {
        return _smallest(tree);
    }

    function getBiggest(Tree storage tree) internal view returns (uint256) {
        return _biggest(tree);
    }

    function getNextSmaller(Tree storage tree, uint256 key) internal view returns (uint256) {
        return _nextSmaller(tree, key);
    }

    function getNextBigger(Tree storage tree, uint256 key) internal view returns (uint256) {
        return _nextBigger(tree, key);
    }

    function getParent(Tree storage tree, uint256 key) internal view returns (uint256) {
        return tree.node[key].parent;
    }

    function getLeft(Tree storage tree, uint256 key) internal view returns (uint256) {
        return tree.node[key].left;
    }

    function getRight(Tree storage tree, uint256 key) internal view returns (uint256) {
        return tree.node[key].right;
    }

    function getHeight(Tree storage tree, uint256 key) internal view returns (uint256) {
        return tree.node[key].height;
    }

    function getNode(Tree storage tree, uint256 key) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        return (tree.node[key].key, tree.node[key].parent, tree.node[key].left, tree.node[key].right, tree.node[key].height);
    }

    function getNodeList(Tree storage tree, uint256[] storage key) internal view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256 len = key.length;
        uint256[] memory keys = new uint256[](len);
        uint256[] memory parent = new uint256[](len);
        uint256[] memory left = new uint256[](len);
        uint256[] memory right = new uint256[](len);
        uint256[] memory height = new uint256[](len);

        for (uint256 i; i<len; i++) {
            keys[i] = tree.node[i].key;
            parent[i] = tree.node[i].parent;
            left[i] = tree.node[i].left;
            right[i] = tree.node[i].right;
            height[i] = tree.node[i].height;
        }

        return (keys, parent, left, right, height);
    }

    function insert(Tree storage tree, uint256 key) internal {
        if (key == 0) {
            revert ZeroKeyNotAllowed();
        }

        if (exists(tree, key)) {
            revert DuplicateKey(key);
        }

        uint256 tmpCur = tree.root;
        uint256 parent;
        bool heightUpdated;
        while (tmpCur != 0) {
            parent = tmpCur;
            if (key < tree.node[tmpCur].key) {
                tmpCur = tree.node[tmpCur].left;
            } else {
                tmpCur = tree.node[tmpCur].right;
            }
        }

        tree.node[key] = Node({
            key: key,
            parent: parent,
            left: 0,
            right: 0,
            height: 1
        });

        if (tree.root == 0) {
            tree.root = key;
            tree.size = 1;
            return;
        }

        if (key < tree.node[parent].key) {
            tree.node[parent].left = key;
            if (tree.node[parent].right == 0) {
                heightUpdated = true;
            }
        } else {
            tree.node[parent].right = key;
            if (tree.node[parent].left == 0) {
                heightUpdated = true;
            }
        }

        if (heightUpdated) {
            _balance(tree, parent);
        }

        tree.size++;
    }

    function remove(Tree storage tree, uint256 key) internal {
        if (key == 0) {
            revert ZeroKeyNotAllowed();
        }

        if (!exists(tree, key)) {
            revert NonExistentKey(key);
        }

        uint256 refNode;
        if (tree.size == 1) {
            /// @dev if `key` is the last(root) node
            _initialize(tree, key);
            tree.root = 0;
            tree.size = 0;
            return;
        } else if (_isLeaf(tree, key)) {
            /// @dev if `key` is leaf node
            refNode = _replace(tree, key, 0);
        } else {
            /// @dev if `key` is not leaf node
            if (tree.node[key].left > 0) {
                refNode = _replace(tree, key, _leftMax(tree, key));
            } else {
                refNode = _replace(tree, key, tree.node[key].right);
            }
        }

        _balance(tree, refNode);
        tree.size--;
    }

    function _isLeaf(Tree storage tree, uint256 key) private view returns (bool) {
        if (tree.node[key].left == 0 && tree.node[key].right == 0) {
            return true;
        } else {
            return false;
        }
    }

    function _smallest(Tree storage tree) private view returns (uint256) {
        uint256 smallest = tree.root;
        uint256 tmpKey = tree.node[smallest].left;

        while (tmpKey != 0) {
            smallest = tmpKey;
            tmpKey = tree.node[tmpKey].left;
        }

        return smallest;
    }

    function _biggest(Tree storage tree) private view returns (uint256) {
        uint256 biggest = tree.root;
        uint256 tmpKey = tree.node[biggest].right;

        while (tmpKey != 0) {
            biggest = tmpKey;
            tmpKey = tree.node[tmpKey].right;
        }

        return biggest;
    }

    function _leftMax(Tree storage tree, uint256 key) private view returns (uint256) {
        uint256 leftMaxChild = tree.node[key].left;

        for (uint256 tmpChild=tree.node[leftMaxChild].right; tmpChild!=0; tmpChild=tree.node[tmpChild].right) {
            leftMaxChild = tmpChild;
        }

        return leftMaxChild;
    }

    function _rightMin(Tree storage tree, uint256 key) private view returns (uint256) {
        uint256 rightMinChild = tree.node[key].right;

        for (uint256 tmpChild=tree.node[rightMinChild].left; tmpChild!=0; tmpChild=tree.node[tmpChild].left) {
            rightMinChild = tmpChild;
        }

        return rightMinChild;
    }

    function _nextBigger(Tree storage tree, uint256 key) private view returns (uint256) {
        uint256 nextBigger;

        if (exists(tree, key)) {
            nextBigger = _rightMin(tree, key);

            if (nextBigger == 0) {
                nextBigger = tree.node[key].parent;
                while (nextBigger < key && nextBigger != 0) {
                    nextBigger = tree.node[nextBigger].parent;
                }
            }
        } else {
            uint256 tmpKey = tree.root;

            while (tmpKey != 0) {
                if (key < tmpKey) {
                    nextBigger = tmpKey;
                    tmpKey = tree.node[tmpKey].left;
                } else {
                    tmpKey = tree.node[tmpKey].right;
                }
            }
        }

        return nextBigger;
    }

    function _nextSmaller(Tree storage tree, uint256 key) private view returns (uint256) {
        uint256 nextSmaller;

        if (exists(tree, key)) {
            nextSmaller = _leftMax(tree, key);

            if (nextSmaller == 0) {
                nextSmaller = tree.node[key].parent;
                while (nextSmaller > key && nextSmaller != 0) {
                    nextSmaller = tree.node[nextSmaller].parent;
                }
            }
        } else {
            uint256 tmpKey = tree.root;

            while (tmpKey != 0) {
                if (key > tmpKey) {
                    nextSmaller = tmpKey;
                    tmpKey = tree.node[tmpKey].right;
                } else {
                    tmpKey = tree.node[tmpKey].left;
                }
            }
        }

        return nextSmaller;
    }

    function _replace(Tree storage tree, uint256 oldKey, uint256 newKey) private returns (uint256) {
        uint256 tmpOldParent = tree.node[oldKey].parent;
        if (tree.node[tmpOldParent].left == oldKey) {
            tree.node[tmpOldParent].left = newKey;
        } else {
            tree.node[tmpOldParent].right = newKey;
        }

        if (newKey == 0) {
            _initialize(tree, oldKey);
            return tmpOldParent;
        }

        if (tree.node[newKey].parent == oldKey) {
            if (tree.node[oldKey].left == newKey) {
                tree.node[newKey].left = 0;
                tree.node[newKey].right = tree.node[oldKey].right;
                tree.node[tree.node[newKey].right].parent = newKey;
            } else {
                tree.node[newKey].left = tree.node[oldKey].left;
                tree.node[newKey].right = 0;
                tree.node[tree.node[newKey].left].parent = newKey;
            }

            tree.node[newKey].parent = tmpOldParent;
            tree.node[newKey].height = tree.node[oldKey].height;
            _initialize(tree, oldKey);
            return newKey;
        } else {
            uint256 tmpNewParent = tree.node[newKey].parent;
            if (tree.node[tmpNewParent].left == newKey) {
                tree.node[tmpNewParent].left = 0;
            } else {
                tree.node[tmpNewParent].right = 0;
            }

            tree.node[newKey].left = tree.node[oldKey].left;
            tree.node[newKey].right = tree.node[oldKey].right;
            tree.node[newKey].parent = tmpOldParent;
            tree.node[newKey].height = tree.node[oldKey].height;

            tree.node[tree.node[newKey].left].parent = newKey;
            tree.node[tree.node[newKey].right].parent = newKey;

            _initialize(tree, oldKey);
            return tmpNewParent;

        }
    }

    function _initialize(Tree storage tree, uint256 key) private {
        tree.node[key].key = 0;
        tree.node[key].parent = 0;
        tree.node[key].left = 0;
        tree.node[key].right = 0;
        tree.node[key].height = 0;
    }

    function _balance(Tree storage tree, uint256 key) private {
        uint256 tmpCur = key;
        while(tmpCur != 0) {
            (uint256 max, int256 diff) = _maxAndDiff(tree.node[tree.node[tmpCur].left].height, tree.node[tree.node[tmpCur].right].height);
            tree.node[tmpCur].height = max + 1;

            if (diff > 1) {
                tmpCur = _rotateRight(tree, tmpCur);
            } else if (diff < -1) {
                tmpCur = _rotateLeft(tree, tmpCur);
            }

            tmpCur = tree.node[tmpCur].parent;
        }
    }

    function _rotateLeft(Tree storage tree, uint256 key) private returns (uint256) {
        uint256 r = tree.node[key].right;
        uint256 rl = tree.node[r].left;
        uint256 rrHeight = tree.node[tree.node[r].right].height;
        uint256 rlHeight = tree.node[rl].height;

        if (rrHeight >= rlHeight) {
            /// @dev Right-Right case -> Single Rotate Left
            uint256 tmpParent = tree.node[key].parent;

            tree.node[key].right = rl;
            tree.node[key].parent = r;
            tree.node[key].height = _max(tree.node[tree.node[key].left].height, tree.node[tree.node[key].right].height) + 1;

            tree.node[r].left = key;
            tree.node[r].parent = tmpParent;
            tree.node[r].height = _max(tree.node[tree.node[r].left].height, tree.node[tree.node[r].right].height) + 1;

            tree.node[rl].parent = key;

            if (tree.node[r].parent == 0) {
                tree.root = r;
            } else {
                if (tree.node[tree.node[r].parent].left == key) {
                    tree.node[tree.node[r].parent].left = r;
                } else {
                    tree.node[tree.node[r].parent].right = r;
                }
            }

            return r;
        } else {
            /// @dev Right-Left case -> Double Rotate Left
            uint256 tmpParent = tree.node[key].parent;
            uint256 rll = tree.node[rl].left;
            uint256 rlr = tree.node[rl].right;

            tree.node[key].right = rll;
            tree.node[key].parent = rl;
            tree.node[key].height = _max(tree.node[tree.node[key].left].height, tree.node[rll].height) + 1;

            tree.node[r].left = rlr;
            tree.node[r].parent = rl;
            tree.node[r].height = _max(tree.node[rlr].height, tree.node[tree.node[r].right].height) + 1;

            tree.node[rl].left = key;
            tree.node[rl].right = r;
            tree.node[rl].parent = tmpParent;
            tree.node[rl].height = _max(tree.node[key].height, tree.node[r].height) + 1;

            tree.node[rlr].parent = r;
            tree.node[rll].parent = key;

            if (tree.node[rl].parent == 0) {
                tree.root = rl;
            } else {
                if (tree.node[tree.node[rl].parent].left == key) {
                    tree.node[tree.node[rl].parent].left = rl;
                } else {
                    tree.node[tree.node[rl].parent].right = rl;
                }
            }

            return rl;
        }
    }

    function _rotateRight(Tree storage tree, uint256 key) private returns (uint256) {
        uint256 l = tree.node[key].left;
        uint256 lr = tree.node[l].right;
        uint256 llHeight = tree.node[tree.node[l].left].height;
        uint256 lrHeight = tree.node[lr].height;

        if (llHeight >= lrHeight) {
            /// @dev Left-Left case -> Single Rotate Right
            uint256 tmpParent = tree.node[key].parent;

            tree.node[key].left = lr;
            tree.node[key].parent = l;
            tree.node[key].height = _max(tree.node[tree.node[key].left].height, tree.node[tree.node[key].right].height) + 1;

            tree.node[l].right = key;
            tree.node[l].parent = tmpParent;
            tree.node[l].height = _max(tree.node[tree.node[l].left].height, tree.node[tree.node[l].right].height) + 1;

            tree.node[lr].parent = key;

            if (tree.node[l].parent == 0) {
                tree.root = l;
            } else {
                if (tree.node[tree.node[l].parent].left == key) {
                    tree.node[tree.node[l].parent].left = l;
                } else {
                    tree.node[tree.node[l].parent].right = l;
                }
            }

            return l;
        } else {
            /// @dev Left-Right case -> Double Rotate Right
            uint256 tmpParent = tree.node[key].parent;
            uint256 lrl = tree.node[lr].left;
            uint256 lrr = tree.node[lr].right;

            tree.node[key].left = lrr;
            tree.node[key].parent = lr;
            tree.node[key].height = _max(tree.node[lrr].height, tree.node[tree.node[key].right].height) + 1;

            tree.node[l].right = lrl;
            tree.node[l].parent = lr;
            tree.node[l].height = _max(tree.node[tree.node[l].left].height, tree.node[lrl].height) + 1;

            tree.node[lr].left = l;
            tree.node[lr].right = key;
            tree.node[lr].parent = tmpParent;
            tree.node[lr].height = _max(tree.node[l].height, tree.node[key].height) + 1;

            tree.node[lrl].parent = l;
            tree.node[lrr].parent = key;

            if (tree.node[lr].parent == 0) {
                tree.root = lr;
            } else {
                if (tree.node[tree.node[lr].parent].left == key) {
                    tree.node[tree.node[lr].parent].left = lr;
                } else {
                    tree.node[tree.node[lr].parent].right = lr;
                }
            }

            return lr;
        }
    }

    function _maxAndDiff(uint256 a, uint256 b) private pure returns (uint256, int256) {
        int diff = int(a) - int(b);
        if (a > b) {
            return (a, diff);
        } else {
            return (b, diff);
        }
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }
}
// pragma solidity ^0.8.27;

// import "hardhat/console.sol";

// library AvlTree {
//     struct Tree {
//         uint256 root;
//         uint256 size;
//         mapping (uint256 => Node) node;
//     }

//     struct Node {
//         uint256 key;
//         uint256 parent;
//         uint256 left;
//         uint256 right;
//         uint256 height;
//     }

//     error ZeroKeyNotAllowed();
//     error NonExistentKey(uint256 key);

//     function exists(Tree storage tree, uint256 key) internal view returns (bool) {
//         return (tree.node[key].key > 0);
//     }

//     function root(Tree storage tree) internal view returns (uint256) {
//         return tree.root;
//     }

//     function size(Tree storage tree) internal view returns (uint256) {
//         return tree.size;
//     }

//     function left(Tree storage tree, uint256 parent) internal view returns (uint256) {
//         return tree.node[parent].left;
//     }

//     function right(Tree storage tree, uint256 parent) internal view returns (uint256) {
//         return tree.node[parent].right;
//     }

//     function getNode(Tree storage tree, uint256 key) internal view returns (uint256, uint256, uint256, uint256) {
//         return (tree.node[key].parent, tree.node[key].left, tree.node[key].right, tree.node[key].height);
//     }

//     function insert(Tree storage tree, uint256 key) internal {
//         if (key == 0) {
//             revert ZeroKeyNotAllowed();
//         }

//         if (exists(tree, key)) {
//             return;
//         }

//         tree.root = _insert(tree, root(tree), key);
//         tree.size++;
//     }

//     function remove(Tree storage tree, uint256 key) internal {
//         if (key == 0) {
//             revert ZeroKeyNotAllowed();
//         }

//         if (!exists(tree, key)) {
//             revert NonExistentKey(key);
//         }

//         tree.root = _remove(tree, root(tree), key);
//         tree.size--;
//     }

//     function _insert(Tree storage tree, uint256 parent, uint256 key) internal returns (uint256) {
//         if (parent == 0) {
//             tree.node[key] = Node({
//                 key: key,
//                 parent: parent,
//                 left: 0,
//                 right: 0,
//                 height: 1
//             });
//             return key;
//         }

//         if (key < tree.node[parent].key) {
//             tree.node[parent].left = _insert(tree, tree.node[parent].left, key);
//             // tree.node[tree.node[parent].left].parent = parent;
//         } else {
//             tree.node[parent].right = _insert(tree, tree.node[parent].right, key);
//             // tree.node[tree.node[parent].right].parent = parent;
//         }
   
//         return _balance(tree, parent);     
//     }

//     function _remove(Tree storage tree, uint256 parent, uint256 key) private returns (uint256) {
//         uint256 tmpKey;

//         if (parent == 0) {
//             return parent;
//         }

//         if (tree.node[parent].key == key) {
//             if (tree.node[parent].left == 0 || tree.node[parent].right == 0) {
//                 if (tree.node[parent].left == 0) {
//                     tmpKey = tree.node[parent].right;
//                 } else {
//                     tmpKey = tree.node[parent].left;
//                 }
//                 tree.node[parent] = tree.node[0];
//                 return tmpKey;
//             } else {
//                 for (tmpKey = tree.node[parent].right; tree.node[tmpKey].left != 0; tmpKey = tree.node[tmpKey].left) {}
//                 tree.node[parent].key = tree.node[tmpKey].key;
//                 tree.node[tmpKey] = tree.node[0];
//                 tree.node[parent].right = _remove(tree, tree.node[parent].right, tree.node[tmpKey].key);
//                 return _balance(tree, parent);
//             }
//         }

//         if (key < tree.node[parent].key) {
//             tree.node[parent].left = _remove(tree, tree.node[parent].left, key);
//         } else {
//             tree.node[parent].right = _remove(tree, tree.node[parent].right, key);
//         }

//         return _balance(tree, parent);
//     }
    
//     function _balance(Tree storage tree, uint256 parent) private returns (uint256) {
//         uint256 pLeft = tree.node[parent].left;
//         uint256 pRight = tree.node[parent].right;

//         if (parent > 0) {
//             if (tree.node[pLeft].height > tree.node[pRight].height) {
//                 tree.node[parent].height = tree.node[pLeft].height + 1;
//             } else {
//                 tree.node[parent].height = tree.node[pRight].height + 1;
//             }
//         }

//         if (tree.node[pLeft].height > tree.node[pRight].height + 1) {
//             if (tree.node[tree.node[pLeft].right].height > tree.node[tree.node[pLeft].left].height) {
//                 tree.node[parent].left = _rotateRight(tree, pLeft);
//             }
//             return _rotateLeft(tree, parent);
//         } else if (tree.node[pRight].height > tree.node[pLeft].height + 1) {
//             if (tree.node[tree.node[pRight].left].height > tree.node[tree.node[pRight].right].height) {
//                 tree.node[parent].right = _rotateLeft(tree, pRight);
//             }
//             return _rotateRight(tree, parent);
//         }

//         console.log("Parent:", parent);
//         return parent;
//     }

//     function _rotateLeft(Tree storage tree, uint256 parent) private returns (uint256) {
//         uint tmpLeft = tree.node[parent].left;
//         tree.node[parent].left = tree.node[tmpLeft].right;
//         tree.node[tmpLeft].right = parent;

//         if (parent > 0) {
//             if (tree.node[tree.node[parent].left].height > tree.node[tree.node[parent].right].height) {
//                 tree.node[parent].height = tree.node[tree.node[parent].left].height + 1;
//             } else {
//                 tree.node[parent].height = tree.node[tree.node[parent].right].height + 1;
//             }
//         }

//         if (tmpLeft > 0) {
//             if (tree.node[tree.node[tmpLeft].left].height > tree.node[tree.node[tmpLeft].right].height) {
//                 tree.node[tmpLeft].height = tree.node[tree.node[tmpLeft].left].height + 1;
//             } else {
//                 tree.node[tmpLeft].height = tree.node[tree.node[tmpLeft].right].height + 1;
//             }
//         }
//         console.log("Left:", tmpLeft);
//         return tmpLeft;
//     }

//     function _rotateRight(Tree storage tree, uint256 parent) private returns (uint256) {
//         uint tmpRight = tree.node[parent].right;
//         tree.node[parent].right = tree.node[tmpRight].left;
//         tree.node[tmpRight].left = parent;

//         if (parent > 0) {
//             if (tree.node[tree.node[parent].left].height > tree.node[tree.node[parent].right].height) {
//                 tree.node[parent].height = tree.node[tree.node[parent].left].height + 1;
//             } else {
//                 tree.node[parent].height = tree.node[tree.node[parent].right].height + 1;
//             }
//         }

//         if (tmpRight > 0) {
//             if (tree.node[tree.node[tmpRight].left].height > tree.node[tree.node[tmpRight].right].height) {
//                 tree.node[tmpRight].height = tree.node[tree.node[tmpRight].left].height + 1;
//             } else {
//                 tree.node[tmpRight].height = tree.node[tree.node[tmpRight].right].height + 1;
//             }
//         }
//         console.log("Right:", tmpRight);
//         return tmpRight;
//     }
// }