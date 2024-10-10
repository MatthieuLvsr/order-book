// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Carnet d'Ordres pour la Gestion de Deux Tokens ERC20
/// @notice Ce contrat permet de gérer un carnet d'ordres entre deux tokens ERC20 distincts.
/// @dev Utilise deux tokens ERC20 pour les échanges : `token1` (actif) et `token2` (paiement).
contract Book {
    /// @notice Adresse du premier token (pour les échanges).
    address public token1;

    /// @notice Adresse du second token (pour les paiements).
    address public token2;

    /// @notice Structure représentant un ordre dans le carnet d'ordres.
    /// @param orderer Adresse de l'utilisateur ayant créé l'ordre.
    /// @param volume Quantité de `token1` dans l'ordre.
    /// @param amount Quantité de `token2` dans l'ordre.
    struct Order {
        address orderer;
        uint256 volume;
        uint256 amount;
    }

    /// @notice Tableau d'ordres d'achat (buy orders).
    Order[] public buys;

    /// @notice Tableau d'ordres de vente (sell orders).
    Order[] public sells;

    /// @notice Événement déclenché lorsqu'un nouvel ordre d'achat est créé.
    /// @param buyer Adresse de l'acheteur.
    /// @param volume Quantité de `token1` demandée.
    /// @param amount Quantité de `token2` offerte.
    event NewBuyOrder(address indexed buyer, uint256 volume, uint256 amount);

    /// @notice Événement déclenché lorsqu'un nouvel ordre de vente est créé.
    /// @param seller Adresse du vendeur.
    /// @param volume Quantité de `token1` mise en vente.
    /// @param amount Quantité de `token2` demandée.
    event NewSellOrder(address indexed seller, uint256 volume, uint256 amount);

    /// @notice Événement déclenché lorsqu'un ordre d'achat et un ordre de vente sont appariés.
    /// @param buyer Adresse de l'acheteur.
    /// @param seller Adresse du vendeur.
    /// @param volume Quantité de `token1` échangée.
    /// @param amount Quantité de `token2` échangée.
    event OrderMatched(
        address indexed buyer,
        address indexed seller,
        uint256 volume,
        uint256 amount
    );

    /// @notice Initialise le contrat avec les adresses des tokens ERC20.
    /// @param _token1 Adresse du premier token ERC20 utilisé pour les échanges.
    /// @param _token2 Adresse du second token ERC20 utilisé pour les paiements.
    /// @dev Les adresses des tokens ne doivent pas être nulles (`address(0)`).
    constructor(address _token1, address _token2) {
        require(_token1 != address(0), "Token1 address cannot be zero");
        require(_token2 != address(0), "Token2 address cannot be zero");
        token1 = _token1;
        token2 = _token2;
    }

    /// @notice Crée un nouvel ordre d'achat pour `token1` en utilisant `token2` comme paiement.
    /// @param _volume Quantité de `token1` souhaitée par l'acheteur.
    /// @param _amount Quantité de `token2` offerte pour `token1`.
    /// @dev L'utilisateur doit avoir approuvé le contrat pour le transfert de `token2`.
    function buy(uint256 _volume, uint256 _amount) public {
        require(_volume > 0, "Insufficient volume");
        require(_amount > 0, "Insufficient amount");
        require(
            IERC20(token2).allowance(msg.sender, address(this)) >= _amount,
            "Insufficient allowance for token2"
        );
        require(
            IERC20(token2).balanceOf(msg.sender) >= _amount,
            "Insufficient token2 balance"
        );

        for (uint i = 0; i < sells.length; i++) {
            if (sells[i].volume == _volume && sells[i].amount == _amount) {
                require(
                    IERC20(token1).transfer(msg.sender, _volume),
                    "Transfer of token1 failed"
                );
                require(
                    IERC20(token2).transferFrom(
                        msg.sender,
                        sells[i].orderer,
                        _amount
                    ),
                    "Transfer of token2 failed"
                );
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

    /// @notice Crée un nouvel ordre de vente pour `token1` en échange de `token2`.
    /// @param _volume Quantité de `token1` mise en vente.
    /// @param _amount Quantité de `token2` demandée pour `token1`.
    /// @dev L'utilisateur doit avoir approuvé le contrat pour le transfert de `token1`.
    function sell(uint256 _volume, uint256 _amount) public {
        require(_volume > 0, "Insufficient volume");
        require(_amount > 0, "Insufficient amount");
        require(
            IERC20(token1).allowance(msg.sender, address(this)) >= _volume,
            "Insufficient allowance for token1"
        );
        require(
            IERC20(token1).balanceOf(msg.sender) >= _volume,
            "Insufficient token1 balance"
        );

        for (uint i = 0; i < buys.length; i++) {
            if (buys[i].volume == _volume && buys[i].amount == _amount) {
                require(
                    IERC20(token1).transferFrom(
                        msg.sender,
                        buys[i].orderer,
                        _volume
                    ),
                    "Transfer of token1 failed"
                );
                require(
                    IERC20(token2).transferFrom(
                        buys[i].orderer,
                        msg.sender,
                        _amount
                    ),
                    "Transfer of token2 failed"
                );
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
            IERC20(token1).transferFrom(msg.sender, address(this), _volume),
            "Transfer of token1 to contract failed"
        );

        sells.push(Order(msg.sender, _volume, _amount));
        emit NewSellOrder(msg.sender, _volume, _amount);
    }

    /// @notice Supprime un ordre de vente du carnet d'ordres.
    /// @param index Index de l'ordre à supprimer.
    /// @dev Supprime l'ordre de vente à l'index spécifié et réorganise le tableau.
    function removeSellOrder(uint index) public {
        require(index < sells.length, "Sell order index out of bounds");

        if (index != sells.length - 1) {
            sells[index] = sells[sells.length - 1];
        }
        sells.pop();
    }

    /// @notice Supprime un ordre d'achat du carnet d'ordres.
    /// @param index Index de l'ordre à supprimer.
    /// @dev Supprime l'ordre d'achat à l'index spécifié et réorganise le tableau.
    function removeBuyOrder(uint index) public {
        require(index < buys.length, "Buy order index out of bounds");

        if (index != buys.length - 1) {
            buys[index] = buys[buys.length - 1];
        }
        buys.pop();
    }

    /// @notice Retourne le nombre total d'ordres d'achat dans le carnet.
    /// @return Nombre d'ordres d'achat.
    function getBuysLength() public view returns (uint256) {
        return buys.length;
    }

    /// @notice Retourne le nombre total d'ordres de vente dans le carnet.
    /// @return Nombre d'ordres de vente.
    function getSellsLength() public view returns (uint256) {
        return sells.length;
    }
}
