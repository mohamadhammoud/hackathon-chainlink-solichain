// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title LendingVault
 * @notice A collateralized lending vault allowing users to deposit ETH and borrow protocol tokens.
 * @dev Uses Chainlink Price Feeds to calculate LTV and trigger liquidation. Includes interest, origination fees, and liquidation rewards.
 */
contract LendingVault is Ownable, ReentrancyGuard {
    IERC20 public stableToken; // SolichainToken (borrowed asset)
    AggregatorV3Interface public ethUsdPriceFeed;

    uint256 public constant MAX_LTV = 50; // 50% max Loan-to-Value
    uint256 public constant LIQUIDATION_THRESHOLD = 75; // Liquidation threshold at 75%
    uint256 public constant ORIGINATION_FEE_BPS = 50; // 0.5% origination fee (basis points)
    uint256 public constant LIQUIDATION_BONUS_BPS = 10_00; // 10% liquidation reward
    uint256 public constant INTEREST_RATE_PER_YEAR = 5_00; // 5% APR (basis points)
    uint256 public constant PRECISION = 1e18;

    struct Position {
        uint256 collateralETH;
        uint256 principalDebt;
        uint256 lastBorrowTimestamp;
    }

    mapping(address => Position) public positions;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 fee);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, uint256 reward);

    /**
     * @notice Initializes the vault with a stable token and Chainlink price feed.
     * @param _stableToken The ERC20 token users borrow (e.g., SolichainToken)
     * @param _priceFeed The Chainlink ETH/USD price feed address
     */
    constructor(address _stableToken, address _priceFeed) {
        stableToken = IERC20(_stableToken);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        deposit();
    }

    /**
     * @notice Deposits ETH as collateral
     */
    function deposit() public payable nonReentrant {
        require(msg.value > 0, "No ETH sent");
        positions[msg.sender].collateralETH += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Borrows stable tokens against ETH collateral
     * @param amount The amount of tokens to borrow
     */
    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");

        Position storage pos = positions[msg.sender];
        uint256 ethPrice = _getEthPrice();
        uint256 collateralUSD = (pos.collateralETH * ethPrice) / 1e8;

        uint256 newDebt = getTotalDebt(msg.sender) + amount;
        uint256 ltv = (newDebt * 100) / collateralUSD;
        require(ltv <= MAX_LTV, "Exceeds LTV");

        uint256 fee = (amount * ORIGINATION_FEE_BPS) / 10000;
        uint256 totalBorrow = amount + fee;

        pos.principalDebt += amount;
        pos.lastBorrowTimestamp = block.timestamp;

        require(stableToken.transfer(msg.sender, amount), "Transfer failed");
        emit Borrowed(msg.sender, amount, fee);
    }

    /**
     * @notice Repays debt
     * @param amount The amount to repay
     */
    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(
            stableToken.transferFrom(msg.sender, address(this), amount),
            "Repayment failed"
        );

        uint256 debt = getTotalDebt(msg.sender);
        require(amount <= debt, "Too much");

        Position storage pos = positions[msg.sender];
        pos.principalDebt = debt - amount;
        pos.lastBorrowTimestamp = block.timestamp;

        emit Repaid(msg.sender, amount);
    }

    /**
     * @notice Withdraws ETH collateral, ensuring LTV is safe
     * @param amount ETH amount to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        Position storage pos = positions[msg.sender];
        require(amount > 0 && pos.collateralETH >= amount, "Invalid amount");

        uint256 ethPrice = _getEthPrice();
        uint256 remainingCollateral = pos.collateralETH - amount;
        uint256 collateralUSD = (remainingCollateral * ethPrice) / 1e8;
        uint256 debt = getTotalDebt(msg.sender);
        uint256 ltv = debt > 0 ? (debt * 100) / collateralUSD : 0;

        require(ltv <= MAX_LTV, "Would exceed LTV");
        pos.collateralETH = remainingCollateral;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Liquidates user position if LTV exceeds threshold
     * @param user The address of the borrower
     */
    function liquidate(address user) external nonReentrant {
        Position storage pos = positions[user];
        require(pos.principalDebt > 0, "No debt");

        uint256 ethPrice = _getEthPrice();
        uint256 collateralUSD = (pos.collateralETH * ethPrice) / 1e8;
        uint256 debt = getTotalDebt(user);
        uint256 ltv = (debt * 100) / collateralUSD;
        require(ltv > LIQUIDATION_THRESHOLD, "Not liquidatable");

        uint256 reward = (pos.collateralETH * LIQUIDATION_BONUS_BPS) / 10000;
        uint256 seized = pos.collateralETH - reward;

        pos.collateralETH = 0;
        pos.principalDebt = 0;
        payable(msg.sender).transfer(reward);

        emit Liquidated(user, reward);
    }

    /**
     * @notice Gets total debt including interest
     * @param user Address of borrower
     * @return Total debt owed
     */
    function getTotalDebt(address user) public view returns (uint256) {
        Position memory pos = positions[user];
        if (pos.principalDebt == 0) return 0;
        uint256 timeElapsed = block.timestamp - pos.lastBorrowTimestamp;
        uint256 interest = (pos.principalDebt *
            INTEREST_RATE_PER_YEAR *
            timeElapsed) / (365 days * 10000);
        return pos.principalDebt + interest;
    }

    /**
     * @notice Gets current LTV of a user
     * @param user The borrower
     * @return LTV percentage
     */
    function getLTV(address user) public view returns (uint256) {
        Position memory pos = positions[user];
        if (pos.principalDebt == 0) return 0;
        uint256 ethPrice = _getEthPrice();
        uint256 collateralUSD = (pos.collateralETH * ethPrice) / 1e8;
        uint256 debt = getTotalDebt(user);
        return (debt * 100) / collateralUSD;
    }

    function _getEthPrice() internal view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }
}
