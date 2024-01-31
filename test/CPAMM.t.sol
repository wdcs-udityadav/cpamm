// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CPAMM} from "../src/CPAMM.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";

contract CPAMMTest is Test {
    CPAMM public cpamm;
    TokenA public tokenA;
    TokenB public tokenB;

    function setUp() public {
        tokenA = new TokenA(address(this));
        tokenB = new TokenB(address(this));

        cpamm = new CPAMM(address(tokenA), address(tokenB));
    }

    function testAddLiquidity() public {
        address lp_provider = vm.addr(1);

        tokenA.mint(lp_provider, 1000);
        tokenB.mint(lp_provider, 1000);
        assertEq(tokenA.balanceOf(lp_provider), 1000);
        assertEq(tokenB.balanceOf(lp_provider), 1000);

        vm.startPrank(lp_provider);
        assertTrue(tokenA.approve(address(cpamm), 1000));
        assertTrue(tokenB.approve(address(cpamm), 500));
        assertEq(cpamm.addLiquidity(1000, 500), 707);
        vm.stopPrank();
    }

    function testSwap() public {
        address lp_provider = vm.addr(1);
        address user = vm.addr(2);

        assertEq(tokenA.balanceOf(lp_provider), 0);
        assertEq(tokenB.balanceOf(lp_provider), 0);
        tokenA.mint(lp_provider, 500);
        tokenB.mint(lp_provider, 500);
        assertEq(tokenA.balanceOf(lp_provider), 500);
        assertEq(tokenB.balanceOf(lp_provider), 500);

        //add liquidity
        vm.startPrank(lp_provider);
        assertTrue(tokenA.approve(address(cpamm), 100));
        assertTrue(tokenB.approve(address(cpamm), 100));
        assertEq(cpamm.addLiquidity(100, 100), 100);
        vm.stopPrank();

        //swap
        tokenA.mint(user, 500);

        vm.startPrank(user);
        assertEq(tokenA.balanceOf(user), 500);
        assertEq(tokenB.balanceOf(user), 0);
        assertTrue(tokenA.approve(address(cpamm), 100));
        assertEq(cpamm.swap(address(tokenA), 100), 49);
        assertEq(tokenA.balanceOf(user), 400);
        assertEq(tokenB.balanceOf(user), 49);
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        address lp_provider = vm.addr(1);

        tokenA.mint(lp_provider, 500);
        tokenB.mint(lp_provider, 500);
        assertEq(tokenA.balanceOf(lp_provider), 500);
        assertEq(tokenB.balanceOf(lp_provider), 500);

        //add liquidity
        vm.startPrank(lp_provider);
        assertTrue(tokenA.approve(address(cpamm), 100));
        assertTrue(tokenB.approve(address(cpamm), 100));
        assertEq(cpamm.addLiquidity(100, 100), 100);

        // remove liquidity
        (uint256 amount0, uint256 amount1) = cpamm.removeLiquidity(100);
        assertEq(amount0, 100);
        assertEq(amount1, 100);
        assertEq(tokenA.balanceOf(lp_provider), 500);
        assertEq(tokenB.balanceOf(lp_provider), 500);
        vm.stopPrank();
    }
}
