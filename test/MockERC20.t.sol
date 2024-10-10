// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol"; 
import "../src/MockERC20.sol"; 
contract MockERC20Test is Test {
    MockERC20 private token;
    address private owner;
    address private user1;
    address private user2;

    // Configuration initiale des tests
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        token = new MockERC20("Test Token", "TST", 18);
    }

    function testDeployment() public {
        assertEq(token.name(), "Test Token", "Token name should be 'Test Token'");
        assertEq(token.symbol(), "TST", "Token symbol should be 'TST'");
        assertEq(token.decimals(), 18, "Token decimals should be 18");
    }

    function testMint() public {
        token.mint(user1, 1000 * 10**18);

        assertEq(token.balanceOf(user1), 1000 * 10**18, "User1 should have 1000 tokens after mint");
    }

    function testApproveAndAllowance() public {
        vm.prank(user1);
        bool success = token.approve(user2, 500 * 10**18);
        assertTrue(success, "Approve should return true");

        assertEq(token.allowance(user1, user2), 500 * 10**18, "Allowance should be 500 tokens");
    }

    function testTransfer() public {
        token.mint(user1, 1000 * 10**18);

        vm.prank(user1);
        bool success = token.transfer(user2, 200 * 10**18);
        assertTrue(success, "Transfer should return true");

        assertEq(token.balanceOf(user1), 800 * 10**18, "User1 should have 800 tokens left");
        assertEq(token.balanceOf(user2), 200 * 10**18, "User2 should have 200 tokens");
    }

    function testTransferFrom() public {
        token.mint(user1, 1000 * 10**18);

        vm.prank(user1);
        token.approve(user2, 300 * 10**18);

        vm.prank(user2);
        bool success = token.transferFrom(user1, user2, 300 * 10**18);
        assertTrue(success, "TransferFrom should return true");

        assertEq(token.balanceOf(user1), 700 * 10**18, "User1 should have 700 tokens left");
        assertEq(token.balanceOf(user2), 300 * 10**18, "User2 should have 300 tokens");
    }

    function testFailTransferFromWithoutApproval() public {
        token.mint(user1, 1000 * 10**18);

        vm.prank(user2);
        token.transferFrom(user1, user2, 100 * 10**18); // Doit échouer car pas d'approbation
    }

    function testFailTransferWithInsufficientBalance() public {
        vm.prank(user1);
        token.transfer(user2, 100 * 10**18); // Doit échouer car `user1` n'a pas de jetons
    }
}
