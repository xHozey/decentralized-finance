//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

contract MockOracle {

    uint256 private ethPrice;
    uint256 private violPrice;
    address deployer;


    constructor() {
        deployer = msg.sender;
    }

    function getEthPrice() public view returns(uint256) {
        return ethPrice;
    }

    function setEthPrice(uint256 price) public {
        require(msg.sender == deployer, "Only deployer can set the price");
        ethPrice = price;
    }

    function getPrice() public view returns (uint256) {
        return violPrice;
    }

    function setPrice(uint256 price) public {
        violPrice = price;
    }
}