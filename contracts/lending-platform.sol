//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Oracle} from "./oracle.sol";
import {LStable} from "./lstable.sol";
import {Lvolatile} from "./lvolatile.sol";
import {Stable} from "./stable.sol";
import {Volatile} from "./volatile.sol";

contract LendingPlatform {
    Volatile public volatile;
    Stable public stable;
    LStable public lStable;
    Lvolatile public lVolatile;
    Oracle public oracle;
    address deployer;
    mapping(address => uint256) public stableDeposits;
    mapping(address => uint256) public volatileDeposits;
    mapping(address => uint256) public borrowedStable;

    constructor(
        address _volatile,
        address _stable,
        address _lStable,
        address _lVolatile
    ) {
        volatile = Volatile(_volatile);
        stable = Stable(_stable);
        lStable = LStable(_lStable);
        lVolatile = Lvolatile(_lVolatile);
        deployer = msg.sender;
    }

    function registerOracle(address oracleAddress_) public {
        require(
            msg.sender == deployer,
            "Only deployer can register the oracle"
        );
        oracle = Oracle(oracleAddress_);
    }

    function depositStable(uint256 amount) external {
        stable.transferFrom(msg.sender, address(this), amount);

        stableDeposits[msg.sender] += amount;
        lStable.mint(msg.sender, amount);
    }

    function depositVolatile(uint256 amount) external {
        volatile.transferFrom(msg.sender, address(this), amount);

        volatileDeposits[msg.sender] += amount;
        lVolatile.mint(msg.sender, amount);
    }

    function borrowStable(uint256 amount) external {
        uint256 price = oracle.getPrice();

        uint256 collateralValue = (volatileDeposits[msg.sender] * price) / 1e18;

        uint256 newDebt = borrowedStable[msg.sender] + amount;

        require(
            collateralValue * 100 >= newDebt * 150,
            "Not enough collateral"
        );

        borrowedStable[msg.sender] = newDebt;
        stable.transfer(msg.sender, amount);
    }

    function liquidate(address user) external {
        uint256 price = oracle.getPrice();

        uint256 collateralValue = (volatileDeposits[user] * price) / 1e18;

        uint256 debt = borrowedStable[user];

        require(debt > 0, "No debt");

        require(collateralValue * 100 < debt * 150, "Position healthy");

        uint256 repayAmount = (debt * 110) / 100;

        stable.transferFrom(msg.sender, address(this), repayAmount);

        volatile.transfer(msg.sender, volatileDeposits[user]);

        borrowedStable[user] = 0;
        volatileDeposits[user] = 0;
    }
}
