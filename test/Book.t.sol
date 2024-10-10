// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Book.sol";
import "../src/MockERC20.sol";

contract BookTest is Test {
    Book private book;
    MockERC20 private token;
    address private owner;
    address private buyer;
    address private seller;

    function setUp() public {
        owner = address(this);
        buyer = address(0x1);
        seller = address(0x2);

        token = new MockERC20("Test Token", "TST", 18);

        book = new Book(address(token));

        deal(address(token), buyer, 1000 * 10 ** 18);
        deal(address(token), seller, 1000 * 10 ** 18);

        vm.prank(seller);
        token.approve(address(book), 1000 * 10 ** 18);

        vm.deal(buyer, 100 ether);
        vm.deal(seller, 100 ether);
    }

    function testConstructorInitialization() public {
        MockERC20 newToken = new MockERC20("New Test Token", "NTST", 18);
        Book newBook = new Book(address(newToken));

        assertEq(
            newBook.token(),
            address(newToken),
            "Token address should be correctly set in the constructor"
        );
    }

    function testBuyOrder() public {
        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        (address orderer, uint256 volume, uint256 amount) = book.buys(0);
        assertEq(orderer, buyer);
        assertEq(volume, 100 * 10 ** 18);
        assertEq(amount, 1 ether);
    }

    function testSellOrder() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 1 ether);
        (address orderer, uint256 volume, uint256 amount) = book.sells(0);
        assertEq(orderer, seller);
        assertEq(volume, 100 * 10 ** 18);
        assertEq(amount, 1 ether);
    }

    function testMatchOrder() public {
        uint256 initialBuyerBalance = buyer.balance; // Solde ETH initial de l'acheteur
        uint256 initialSellerBalance = seller.balance; // Solde ETH initial du vendeur
        uint256 initialBuyerTokenBalance = token.balanceOf(buyer); // Solde en tokens initial de l'acheteur
        uint256 initialSellerTokenBalance = token.balanceOf(seller); // Solde en tokens initial du vendeur

        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        assertEq(
            book.getBuysLength(),
            1,
            "Buy order length should be 1 after placing buy order"
        );
        console.log(
            "Buy order placed. Buy order length:",
            book.getBuysLength()
        );

        vm.prank(seller);
        book.sell(100 * 10 ** 18, 1 ether);

        uint256 sellsLengthAfter = book.getSellsLength();
        uint256 buysLengthAfter = book.getBuysLength();

        console.log("Sell order length after matching:", sellsLengthAfter);
        console.log("Buy order length after matching:", buysLengthAfter);

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

        uint256 finalBuyerBalance = buyer.balance; // Solde ETH final de l'acheteur
        uint256 finalSellerBalance = seller.balance; // Solde ETH final du vendeur
        uint256 finalBuyerTokenBalance = token.balanceOf(buyer); // Solde en tokens final de l'acheteur
        uint256 finalSellerTokenBalance = token.balanceOf(seller); // Solde en tokens final du vendeur

        uint256 expectedBuyerBalance = initialBuyerBalance - 1 ether; // Le buyer dépense 1 ETH
        uint256 expectedSellerBalance = initialSellerBalance + 1 ether; // Le seller reçoit 1 ETH
        uint256 expectedBuyerTokenBalance = initialBuyerTokenBalance +
            (100 * 10 ** 18); // Le buyer reçoit 100 tokens TST
        uint256 expectedSellerTokenBalance = initialSellerTokenBalance -
            (100 * 10 ** 18); // Le seller envoie 100 tokens TST

        assertEq(
            finalBuyerBalance,
            expectedBuyerBalance,
            "Buyer should have 1 ether less"
        );
        assertEq(
            finalSellerBalance,
            expectedSellerBalance,
            "Seller should receive 1 ether"
        );
        assertEq(
            finalBuyerTokenBalance,
            expectedBuyerTokenBalance,
            "Buyer should receive tokens"
        );
        assertEq(
            finalSellerTokenBalance,
            expectedSellerTokenBalance,
            "Seller should send tokens"
        );
    }

    function testFailInvalidOrderMatch() public {
        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        vm.prank(seller);

        vm.expectRevert();
        book.sell(200 * 10 ** 18, 2 ether);

        assertEq(book.getSellsLength(), 1, "Sell order should not be matched");
        assertEq(book.getBuysLength(), 1, "Buy order should not be matched");
    }

    function testFailBuyWithIncorrectETHAmount() public {
        vm.prank(buyer);
        book.buy{value: 0.5 ether}(100 * 10 ** 18, 1 ether); // Envoie 0.5 ETH au lieu de 1 ETH
    }

    function testRemoveBuyOrder() public {
        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        assertEq(book.getBuysLength(), 1);

        book.removeBuyOrder(0);

        assertEq(book.getBuysLength(), 0);
    }

    function testRemoveSellOrder() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 1 ether);

        assertEq(book.getSellsLength(), 1);

        book.removeSellOrder(0);

        assertEq(book.getSellsLength(), 0);
    }

    function testFailRemoveSellOrderOutOfBounds() public {
        book.removeSellOrder(0); // Essaye de supprimer alors qu'il n'y a pas d'ordres
    }

    function testFailRemoveBuyOrderOutOfBounds() public {
        book.removeBuyOrder(0); // Essaye de supprimer alors qu'il n'y a pas d'ordres
    }

    function testBuyLength() public {
        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);
        assertEq(book.getBuysLength(), 1);
    }

    function testSellLength() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 1 ether);
        assertEq(book.getSellsLength(), 1);
    }

    function testBuyOrderWithExistingSell() public {
        uint256 initialBuyerBalance = buyer.balance; // Solde ETH initial de l'acheteur
        uint256 initialSellerBalance = seller.balance; // Solde ETH initial du vendeur
        uint256 initialBuyerTokenBalance = token.balanceOf(buyer); // Solde en tokens initial de l'acheteur
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 1 ether);

        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

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

        uint256 finalBuyerBalance = buyer.balance; // Solde ETH final de l'acheteur
        uint256 finalSellerBalance = seller.balance; // Solde ETH final du vendeur
        uint256 finalBuyerTokenBalance = token.balanceOf(buyer); // Solde en tokens final de l'acheteur

        assertEq(
            finalBuyerTokenBalance,
            initialBuyerTokenBalance + 100 * 10 ** 18,
            "Buyer should receive tokens"
        );
        assertEq(
            finalBuyerBalance,
            initialBuyerBalance - 1 ether,
            "Buyer should have 1 ether less"
        );
        assertEq(
            finalSellerBalance,
            initialSellerBalance + 1 ether,
            "Seller should receive 1 ether"
        );
    }

    function testSellOrderWithExistingBuy() public {
        uint256 initialBuyerBalance = buyer.balance; // Solde ETH initial de l'acheteur
        uint256 initialSellerBalance = seller.balance; // Solde ETH initial du vendeur
        uint256 initialBuyerTokenBalance = token.balanceOf(buyer); // Solde en tokens initial de l'acheteur
        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        vm.prank(seller);
        book.sell(100 * 10 ** 18, 1 ether);

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

        uint256 finalBuyerBalance = buyer.balance; // Solde ETH final de l'acheteur
        uint256 finalSellerBalance = seller.balance; // Solde ETH final du vendeur
        uint256 finalBuyerTokenBalance = token.balanceOf(buyer); // Solde en tokens final de l'acheteur

        assertEq(
            finalBuyerTokenBalance,
            initialBuyerTokenBalance + 100 * 10 ** 18,
            "Buyer should receive tokens"
        );
        assertEq(
            finalBuyerBalance,
            initialBuyerBalance - 1 ether,
            "Buyer should have 1 ether less"
        );
        assertEq(
            finalSellerBalance,
            initialSellerBalance + 1 ether,
            "Seller should receive 1 ether"
        );
    }

    function testRemoveSellOrderWithMultipleOrders() public {
        vm.prank(seller);
        book.sell(100 * 10 ** 18, 1 ether);
        vm.prank(seller);
        book.sell(200 * 10 ** 18, 2 ether);

        assertEq(book.getSellsLength(), 2, "Sell orders length should be 2");

        book.removeSellOrder(0);

        assertEq(
            book.getSellsLength(),
            1,
            "Sell orders length should be 1 after removal"
        );

        (address orderer, uint256 volume, uint256 amount) = book.sells(0);
        assertEq(orderer, seller, "Orderer should be the seller");
        assertEq(volume, 200 * 10 ** 18, "Volume should be 200 TST");
        assertEq(amount, 2 ether, "Amount should be 2 ETH");
    }

    function testRemoveBuyOrderWithMultipleOrders() public {
        vm.prank(buyer);
        book.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);
        vm.prank(buyer);
        book.buy{value: 2 ether}(200 * 10 ** 18, 2 ether);

        assertEq(book.getBuysLength(), 2, "Buy orders length should be 2");

        book.removeBuyOrder(0);

        assertEq(
            book.getBuysLength(),
            1,
            "Buy orders length should be 1 after removal"
        );

        (address orderer, uint256 volume, uint256 amount) = book.buys(0);
        assertEq(orderer, buyer, "Orderer should be the buyer");
        assertEq(volume, 200 * 10 ** 18, "Volume should be 200 TST");
        assertEq(amount, 2 ether, "Amount should be 2 ETH");
    }
}
