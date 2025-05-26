// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockPriceFeed
 * @dev A simple mock Chainlink AggregatorV3Interface for testnets.
 *      Allows manual price updates to simulate real-world price changes.
 */
contract MockPriceFeed is AggregatorV3Interface {
    int256 private price;
    uint8 public override decimals;
    string public override description;
    uint256 public override version = 1;

    uint80 private roundId = 1;
    uint256 private startedAt = block.timestamp;
    uint256 private updatedAt = block.timestamp;
    uint80 private answeredInRound = 1;

    constructor(
        int256 _initialPrice,
        uint8 _decimals,
        string memory _description
    ) {
        price = _initialPrice;
        decimals = _decimals;
        description = _description;
    }

    /**
     * @notice Set the latest mock price (manually called by deployer for testing)
     * @param _price The new ETH/USD price (e.g. 2000e8 for $2,000)
     */
    function updatePrice(int256 _price) external {
        price = _price;
        updatedAt = block.timestamp;
        roundId++;
        answeredInRound = roundId;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (roundId, price, startedAt, updatedAt, answeredInRound);
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        // For simplicity, return current round data for all _roundId
        return (_roundId, price, startedAt, updatedAt, answeredInRound);
    }
}
