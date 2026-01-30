// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Oracle} from "./oracle.sol";

contract StableCoin is ERC20 {
    mapping(address => uint256) public collateralETH;   
    mapping(address => uint256) public debt;

    Oracle public oracle;
    address public owner;

    constructor() ERC20("Stable Coin", "STC") {
        owner = msg.sender;
    }

    function registerOracle(address oracleAddress) public {
        require(msg.sender == owner, "Only owner can register oracle");
        oracle = Oracle(oracleAddress);
    }

    function deposit() public payable {
        require(msg.value > 0, "No ETH sent");
        collateralETH[msg.sender] += msg.value;
    }

    function mint(uint256 amount) public {
        uint256 ethPrice = oracle.getEthPrice();

        uint256 collateralValue = (collateralETH[msg.sender] * ethPrice) / 1e18;

        require(
            (debt[msg.sender] + amount) * 2 <= collateralValue,
            "Insufficient collateral"
        );

        debt[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Amount higher than current balance");
        require(debt[msg.sender] >= amount, "Too much burn");
        require(amount > 0, "Amount must be greater than zero");
        debt[msg.sender] -= amount;
        _burn(msg.sender, amount);
    }

    function withdraw(uint256 ethAmount) public {
        uint256 ethPrice = oracle.getEthPrice();

        uint256 remainingCollateral = collateralETH[msg.sender] - ethAmount;

        uint256 remainingValue = (remainingCollateral * ethPrice) / 1e18;

        require(
            remainingValue >= debt[msg.sender] * 2,
            "Position would be unsafe"
        );

        collateralETH[msg.sender] = remainingCollateral;
        payable(msg.sender).transfer(ethAmount);
    }

    function liquidate(address user) public {
        uint256 ethPrice = oracle.getEthPrice();

        uint256 collateralValue = (collateralETH[user] * ethPrice) / 1e18;

        require(collateralValue < debt[user] * 2, "Position is healthy");

        _burn(msg.sender, debt[user]);

        uint256 reward = (collateralETH[user] * 80) / 100;

        collateralETH[user] = 0;
        debt[user] = 0;

        payable(msg.sender).transfer(reward);
    }
}
