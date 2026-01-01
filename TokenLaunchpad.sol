// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenLaunchpad {
    address public owner;
    IERC20 public token;
    uint256 public tokenPrice; // in wei per token
    uint256 public tokensForSale;
    uint256 public tokensSold;
    bool public saleActive;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 value);
    event SaleStarted(uint256 tokensForSale, uint256 tokenPrice);
    event SaleEnded(uint256 tokensSold);
    event FundsWithdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    function startSale(uint256 _tokensForSale, uint256 _tokenPrice) external onlyOwner {
        require(!saleActive, "Sale already active");
        tokensForSale = _tokensForSale;
        tokenPrice = _tokenPrice;
        tokensSold = 0;
        saleActive = true;
        emit SaleStarted(_tokensForSale, _tokenPrice);
    }

    function buyTokens(uint256 amount) external payable {
        require(saleActive, "Sale not active");
        require(amount > 0, "Amount must be > 0");
        require(tokensSold + amount <= tokensForSale, "Not enough tokens left");
        uint256 cost = amount * tokenPrice;
        require(msg.value >= cost, "Insufficient ETH sent");
        tokensSold += amount;
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit TokensPurchased(msg.sender, amount, cost);
        // Refund excess ETH
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function endSale() external onlyOwner {
        require(saleActive, "Sale not active");
        saleActive = false;
        emit SaleEnded(tokensSold);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }
}
