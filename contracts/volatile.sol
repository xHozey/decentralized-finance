//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Volatile is ERC20("Volatile", "VLT") {
    constructor() {
        _mint(msg.sender, 1000000);
    }
}
