//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {StableCoin} from "./stablecoin.sol";
import {Test} from "forge-std/Test.sol";
import {MockOracle} from "./MockOracle.sol";

contract StableCointTest is Test {
    StableCoin stablecoin;
    MockOracle oracle;

    function setUp() public {
        stablecoin = new StableCoin();
        oracle = new MockOracle();
        stablecoin.registerOracle(address(oracle));
        oracle.setEthPrice(2000);
    }

    receive() external payable {}

    function testRegisterOracle_setOracle_whenCalledByOwner() public {
        stablecoin.registerOracle(address(0x1234));
        assertEq(
            address(stablecoin.oracle()),
            address(0x1234),
            "Oracle not registered correctly"
        );
    }

    function testRegisterOracle_setOracle_whenCalledByStranger() public {
        address notOwner = address(0x5678);
        vm.prank(notOwner);
        vm.expectRevert();
        stablecoin.registerOracle(address(0x1234));
    }

    function testDeposit_recoredCollateral_WhenETHSent() public {
        vm.deal(address(this), 1 ether);
        stablecoin.deposit{value: 1 ether}();
        uint amount = stablecoin.collateralETH(address(this));
        assertEq(amount, 1 ether, "Deposit not recorded correctly");
    }

    function testDeposit_revert_whenNoETHSent() public {
        vm.expectRevert();
        stablecoin.deposit{value: 0}();
    }

    function testMint_increaseDebt_whenMintingCorrectAmount() public {
        uint256 ethPrice = stablecoin.oracle().getEthPrice();
        stablecoin.deposit{value: 1 ether}();
        uint256 toMint = (1 ether * ethPrice) / 1e18 / 2;
        stablecoin.mint(toMint);
        uint256 debt = stablecoin.debt(address(this));
        assertEq(debt, toMint, "Debt not recorded correctly");
    }

    function testMint_increaseBalance_whenMintingCorrectAmount() public {
        uint256 ethPrice = stablecoin.oracle().getEthPrice();
        stablecoin.deposit{value: 1 ether}();
        uint256 toMint = (1 ether * ethPrice) / 1e18 / 2;
        stablecoin.mint(toMint);
        uint256 balance = stablecoin.balanceOf(address(this));
        assertEq(balance, toMint, "Balance not increased correctly");
    }

    function testMint_revert_whenMintingWrongAmount() public {
        uint256 ethPrice = stablecoin.oracle().getEthPrice();
        stablecoin.deposit{value: 1 ether}();
        uint256 toMint = (1 ether * ethPrice) / 1e18;
        vm.expectRevert();
        stablecoin.mint(toMint);
    }

    function testBurn_decreaseDebt_whenBurnCorrectAmount() public {
        uint256 ethPrice = stablecoin.oracle().getEthPrice();
        stablecoin.deposit{value: 1 ether}();
        uint256 toMint = (1 ether * ethPrice) / 1e18 / 2;
        stablecoin.mint(toMint);
        stablecoin.burn(toMint / 2);
        uint256 debt = stablecoin.debt(address(this));
        assertEq(debt, toMint - toMint / 2, "Debt not reduced correctly");
    }

    function testBurn_decreaseBalance_whenBurnCorrectAmount() public {
        uint256 ethPrice = stablecoin.oracle().getEthPrice();
        stablecoin.deposit{value: 1 ether}();
        uint256 toMint = (1 ether * ethPrice) / 1e18 / 2;
        stablecoin.mint(toMint);
        stablecoin.burn(toMint / 2);
        uint256 balance = stablecoin.balanceOf(address(this));
        assertEq(balance, toMint - toMint / 2, "Balance not reduced correctly");
    }

    function testBurn_revert_whenAmountHigherThanBalance() public {
        uint256 ethPrice = stablecoin.oracle().getEthPrice();
        stablecoin.deposit{value: 1 ether}();
        uint256 toMint = (1 ether * ethPrice) / 1e18 / 2;
        stablecoin.mint(toMint);
        vm.expectRevert();
        stablecoin.burn(toMint + 1);
    }

    function testBurn_revert_whenNoAmountSent() public {
        vm.expectRevert();
        stablecoin.burn(0);
    }

    function testBurn_revert_whenAmountHigherThanDebt() public {
        deal(address(stablecoin), address(this), 100 ether);
        assertEq(stablecoin.balanceOf(address(this)), 100 ether);
        assertEq(stablecoin.debt(address(this)), 0);

        vm.expectRevert("Too much burn");
        stablecoin.burn(1 ether);
    }

    function testWithdraw_retrievesCollateral_whenNoDebt() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = depositAmount - depositAmount / 2;

        uint256 balanceBefore = address(this).balance;

        stablecoin.deposit{value: depositAmount}();

        assertEq(stablecoin.debt(address(this)), 0);

        stablecoin.withdraw(withdrawAmount);

        uint256 balanceAfter = address(this).balance;

        assertEq(
            balanceAfter,
            balanceBefore - depositAmount + withdrawAmount,
            "ETH not withdrawn correctly"
        );
    }

    function testWithdraw_revert_whenHaveDebt() public {
        uint256 ethPrice = stablecoin.oracle().getEthPrice();
        stablecoin.deposit{value: 1 ether}();
        uint256 toMint = (1 ether * ethPrice) / 1e18 / 2;
        stablecoin.mint(toMint);

        vm.expectRevert();
        stablecoin.withdraw(1 ether / 2);
    }

    function testWithdraw_revert_whenNoETHLeft() public {
        vm.expectRevert();
        stablecoin.withdraw(1 ether);
    }

    
}
