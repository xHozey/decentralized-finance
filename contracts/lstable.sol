//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LStable is ERC20("lStable", "LSTBL") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
