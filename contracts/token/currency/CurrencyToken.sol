// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Lock} from "../extension/ERC20Lock.sol";

contract CurrencyToken is ERC20Lock {

    constructor() ERC20Lock("CurrencyToken", "CT") {
    }

    function issue(address to, uint256 amount) external virtual {
        _mint(to, amount);
    }
}

// import {ERC20Lock} from "../extension/ERC20Lock.sol";

// contract CurrencyToken is ERC20Lock {
//     bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

//     constructor() ERC20Lock("CurrencyToken", "CT") {
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
//         _grantRole(ISSUER_ROLE, _msgSender());
//     }

//     function issue(address to, uint256 amount) external virtual onlyRole(ISSUER_ROLE) {
//         _mint(to, amount);
//     }
// }