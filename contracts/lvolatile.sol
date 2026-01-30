//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lvolatile is ERC20("lVolatile", "LVLT") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
