// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Book.sol";
import "../src/MockERC20.sol";

contract BookTest is Test {
    Book private book;
    MockERC20 private token1;
    MockERC20 private token2;
    address private owner;
    address private buyer;
    address private seller;

    function setUp() public {
        owner = address(this);
        buyer = address(0x1);
        seller = address(0x2);

        token1 = new MockERC20("Test Token 1", "TST1", 18);
        token2 = new MockERC20("Test Token 2", "TST2", 18);

        book = new Book(address(token1), address(token2));

        deal(address(token1), buyer, 1000 * 10 ** 18);
        deal(address(token1), seller, 1000 * 10 ** 18);
        deal(address(token2), buyer, 1000 * 10 ** 18);
        deal(address(token2), seller, 1000 * 10 ** 18);

        vm.prank(seller);
        token1.approve(address(book), 1000 * 10 ** 18);
        vm.prank(seller);
        token2.approve(address(book), 1000 * 10 ** 18);

        vm.prank(buyer);
        token2.approve(address(book), 1000 * 10 ** 18);
    }

    function testConstructorWithValidAddresses() public {
        MockERC20 newToken1 = new MockERC20("Token1", "TK1", 18);
        MockERC20 newToken2 = new MockERC20("Token2", "TK2", 18);
        Book newBook = new Book(address(newToken1), address(newToken2));

        assertEq(
            newBook.token1(),
            address(newToken1),
            "Token1 address should be set correctly"
        );
        assertEq(
            newBook.token2(),
            address(newToken2),
            "Token2 address should be set correctly"
        );
    }

    function testFailConstructorWithZeroAddressToken1() public {
        MockERC20 newToken2 = new MockERC20("Token2", "TK2", 18);

        new Book(address(0), address(newToken2));
    }

    function testFailConstructorWithZeroAddressToken2() public {
        MockERC20 newToken1 = new MockERC20("Token1", "TK1", 18);

        new Book(address(newToken1), address(0));
    }

    function testBuyOrder() public {
        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 10 * 10 ** 18);

        (address orderer, uint256 volume, uint256 amount) = book.buys(0);
        assertEq(orderer, buyer);
        assertEq(volume, 100 * 10 ** 18);
        assertEq(amount, 10 * 10 ** 18);
    }

    function testSellOrder() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 10 * 10 ** 18);

        (address orderer, uint256 volume, uint256 amount) = book.sells(0);
        assertEq(orderer, seller);
        assertEq(volume, 100 * 10 ** 18);
        assertEq(amount, 10 * 10 ** 18);
    }

    function testMatchOrder() public {
        uint256 initialBuyerToken1Balance = token1.balanceOf(buyer); // Solde en token1 initial de l'acheteur
        uint256 initialSellerToken1Balance = token1.balanceOf(seller); // Solde en token1 initial du vendeur
        uint256 initialBuyerToken2Balance = token2.balanceOf(buyer); // Solde en token2 initial de l'acheteur
        uint256 initialSellerToken2Balance = token2.balanceOf(seller); // Solde en token2 initial du vendeur

        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 10 * 10 ** 18);

        assertEq(
            book.getBuysLength(),
            1,
            "Buy order length should be 1 after placing buy order"
        );

        vm.prank(seller);
        book.sell(100 * 10 ** 18, 10 * 10 ** 18);

        uint256 sellsLengthAfter = book.getSellsLength();
        uint256 buysLengthAfter = book.getBuysLength();

        assertEq(
            sellsLengthAfter,
            0,
            "Sell order should be removed after matching"
        );
        assertEq(
            buysLengthAfter,
            0,
            "Buy order should be removed after matching"
        );

        uint256 finalBuyerToken1Balance = token1.balanceOf(buyer);
        uint256 finalSellerToken1Balance = token1.balanceOf(seller);
        uint256 finalBuyerToken2Balance = token2.balanceOf(buyer);
        uint256 finalSellerToken2Balance = token2.balanceOf(seller);

        assertEq(
            finalBuyerToken1Balance,
            initialBuyerToken1Balance + 100 * 10 ** 18,
            "Buyer should receive tokens1"
        );
        assertEq(
            finalSellerToken1Balance,
            initialSellerToken1Balance - 100 * 10 ** 18,
            "Seller should send tokens1"
        );
        assertEq(
            finalBuyerToken2Balance,
            initialBuyerToken2Balance - 10 * 10 ** 18,
            "Buyer should have 10 token2 less"
        );
        assertEq(
            finalSellerToken2Balance,
            initialSellerToken2Balance + 10 * 10 ** 18,
            "Seller should receive 10 token2"
        );
    }

    function testFailInvalidOrderMatch() public {
        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 10 * 10 ** 18);

        vm.prank(seller);
        vm.expectRevert();
        book.sell(200 * 10 ** 18, 20 * 10 ** 18);

        assertEq(book.getSellsLength(), 1, "Sell order should not be matched");
        assertEq(book.getBuysLength(), 1, "Buy order should not be matched");
    }

    function testRemoveBuyOrder() public {
        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 10 * 10 ** 18);

        assertEq(book.getBuysLength(), 1);

        book.removeBuyOrder(0);

        assertEq(book.getBuysLength(), 0);
    }

    function testRemoveSellOrder() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 10 * 10 ** 18);

        assertEq(book.getSellsLength(), 1);

        book.removeSellOrder(0);

        assertEq(book.getSellsLength(), 0);
    }

    function testFailRemoveSellOrderOutOfBounds() public {
        book.removeSellOrder(0);
    }

    function testFailRemoveBuyOrderOutOfBounds() public {
        book.removeBuyOrder(0);
    }

    function testBuyOrderWithExistingSell() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 10 * 10 ** 18);

        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 10 * 10 ** 18);

        assertEq(
            book.getBuysLength(),
            0,
            "Buy order should be matched and removed"
        );
        assertEq(
            book.getSellsLength(),
            0,
            "Sell order should be matched and removed"
        );
    }

    function testSellOrderWithExistingBuy() public {
        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 10 * 10 ** 18);

        vm.prank(seller);
        book.sell(100 * 10 ** 18, 10 * 10 ** 18);

        assertEq(
            book.getBuysLength(),
            0,
            "Buy order should be matched and removed"
        );
        assertEq(
            book.getSellsLength(),
            0,
            "Sell order should be matched and removed"
        );
    }

    function testRemoveSellOrderNotLast() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 10 * 10 ** 18); // Index 0
        vm.prank(seller);
        book.sell(200 * 10 ** 18, 20 * 10 ** 18); // Index 1

        book.removeSellOrder(0);

        assertEq(
            book.getSellsLength(),
            1,
            "There should be one sell order left"
        );
        (address orderer, uint256 volume, uint256 amount) = book.sells(0);
        assertEq(orderer, seller);
        assertEq(volume, 200 * 10 ** 18, "Volume should be 200 TST");
        assertEq(amount, 20 * 10 ** 18, "Amount should be 20 token2");
    }

    function testRemoveBuyOrderNotLast() public {
        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 10 * 10 ** 18); // Index 0
        vm.prank(buyer);
        book.buy(200 * 10 ** 18, 20 * 10 ** 18); // Index 1

        book.removeBuyOrder(0);

        assertEq(book.getBuysLength(), 1, "There should be one buy order left");
        (address orderer, uint256 volume, uint256 amount) = book.buys(0);
        assertEq(orderer, buyer);
        assertEq(volume, 200 * 10 ** 18, "Volume should be 200 TST");
        assertEq(amount, 20 * 10 ** 18, "Amount should be 20 token2");
    }

    function testFailBuyWithZeroAmount() public {
        vm.prank(buyer);
        book.buy(100 * 10 ** 18, 0); // Doit échouer car l'amount est 0
    }

    function testFailSellWithZeroVolume() public {
        vm.prank(seller);
        book.sell(0, 10 * 10 ** 18); // Doit échouer car le volume est 0
    }
}
