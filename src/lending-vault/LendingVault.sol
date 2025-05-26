// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title LendingVault
 * @dev A collateralized lending vault where users deposit ETH to borrow protocol tokens.
 *      Supports price-based liquidation using Chainlink Price Feeds.
 */
contract LendingVault is Ownable, ReentrancyGuard {
    IERC20 public stableToken; // SolichainToken (borrowed asset)
    AggregatorV3Interface public ethUsdPriceFeed; // Chainlink price feed

    uint256 public constant MAX_LTV = 50; // 50% max LTV
    uint256 public constant LIQUIDATION_THRESHOLD = 75; // Liquidation at 75% LTV
    uint256 public constant PRECISION = 1e18;

    struct Position {
        uint256 collateralETH;
        uint256 debt;
    }

    mapping(address => Position) public positions;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user);

    constructor(address _stableToken, address _priceFeed) {
        stableToken = IERC20(_stableToken);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable nonReentrant {
        require(msg.value > 0, "No ETH sent");
        positions[msg.sender].collateralETH += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");

        Position storage pos = positions[msg.sender];
        uint256 ethPrice = _getEthPrice();
        uint256 collateralUSD = (pos.collateralETH * ethPrice) / 1e8;

        uint256 newDebt = pos.debt + amount;
        uint256 ltv = (newDebt * 100) / collateralUSD;
        require(ltv <= MAX_LTV, "Exceeds LTV");

        pos.debt = newDebt;
        require(
            stableToken.transfer(msg.sender, amount),
            "Token transfer failed"
        );
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(
            stableToken.transferFrom(msg.sender, address(this), amount),
            "Repayment failed"
        );

        Position storage pos = positions[msg.sender];
        pos.debt -= amount;
        emit Repaid(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        Position storage pos = positions[msg.sender];
        require(amount > 0 && pos.collateralETH >= amount, "Invalid amount");

        uint256 ethPrice = _getEthPrice();
        uint256 remainingCollateral = pos.collateralETH - amount;
        uint256 collateralUSD = (remainingCollateral * ethPrice) / 1e8;
        uint256 ltv = pos.debt > 0 ? (pos.debt * 100) / collateralUSD : 0;

        require(ltv <= MAX_LTV, "Would exceed LTV");
        pos.collateralETH = remainingCollateral;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function liquidate(address user) external nonReentrant {
        Position storage pos = positions[user];
        require(pos.debt > 0, "No debt");

        uint256 ethPrice = _getEthPrice();
        uint256 collateralUSD = (pos.collateralETH * ethPrice) / 1e8;
        uint256 ltv = (pos.debt * 100) / collateralUSD;
        require(ltv > LIQUIDATION_THRESHOLD, "Not liquidatable");

        pos.collateralETH = 0;
        pos.debt = 0;
        emit Liquidated(user);
    }

    function getLTV(address user) public view returns (uint256) {
        Position memory pos = positions[user];
        if (pos.debt == 0) return 0;
        uint256 ethPrice = _getEthPrice();
        uint256 collateralUSD = (pos.collateralETH * ethPrice) / 1e8;
        return (pos.debt * 100) / collateralUSD;
    }

    function _getEthPrice() internal view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }
}
