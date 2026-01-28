//SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StableCoin is ERC20 {
    constructor(uint256 initialSupply) ERC20("Stable Coin", "STC") {
        _mint(msg.sender, initialSupply);
        
    }

}
