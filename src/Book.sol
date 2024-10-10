// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Book {
    address public token; // TODO: Repasser en private, public pour les tests

    struct Order {
        address orderer;
        uint256 volume;
        uint256 amount;
    }

    Order[] public buys;
    Order[] public sells;

    event NewBuyOrder(address indexed buyer, uint256 volume, uint256 amount);
    event NewSellOrder(address indexed seller, uint256 volume, uint256 amount);
    event OrderMatched(
        address indexed buyer,
        address indexed seller,
        uint256 volume,
        uint256 amount
    );

    constructor(address _token) {
        token = _token;
    }

    function buy(uint256 _volume, uint256 _amount) public payable {
        require(msg.value == _amount, "Incorrect ETH amount sent");
        for (uint i = 0; i < sells.length; i++) {
            if (sells[i].volume == _volume && sells[i].amount == _amount) {
                require(
                    IERC20(token).transfer(msg.sender, _volume),
                    "Transfer of token failed"
                );
                (bool success, ) = sells[i].orderer.call{value: _amount}("");
                require(success, "Transfer of ETH failed");
                emit OrderMatched(
                    msg.sender,
                    sells[i].orderer,
                    _volume,
                    _amount
                );
                removeSellOrder(i);
                return;
            }
        }
        buys.push(Order(msg.sender, _volume, _amount));
        emit NewBuyOrder(msg.sender, _volume, _amount);
    }

    function sell(uint256 _volume, uint256 _amount) public {
        for (uint i = 0; i < buys.length; i++) {
            if (buys[i].volume == _volume && buys[i].amount == _amount) {
                require(
                    IERC20(token).transferFrom(
                        msg.sender,
                        buys[i].orderer,
                        _volume
                    ),
                    "Transfer of token failed"
                );
                (bool success, ) = payable(msg.sender).call{value: _amount}("");
                require(success, "Transfer of ETH failed");
                emit OrderMatched(
                    buys[i].orderer,
                    msg.sender,
                    _volume,
                    _amount
                );
                removeBuyOrder(i);
                return;
            }
        }
        require(
            IERC20(token).transferFrom(msg.sender, address(this), _volume),
            "Transfer of token failed"
        );
        sells.push(Order(msg.sender, _volume, _amount));
        emit NewSellOrder(msg.sender, _volume, _amount);
    }

    function removeSellOrder(uint index) public { // TODO: Mettre en private avant la prod, public pour les tests
        if (index != sells.length - 1) {
            sells[index] = sells[sells.length - 1];
        }
        sells.pop();
    }
    
    function removeBuyOrder(uint index) public { // TODO: Mettre en private avant la prod, public pour les tests
        if (index != buys.length - 1) {
            buys[index] = buys[buys.length - 1];
        }
        buys.pop();
    }

    function getBuysLength() public view returns (uint256) {
        return buys.length;
    }

    function getSellsLength() public view returns (uint256) {
        return sells.length;
    }
}
