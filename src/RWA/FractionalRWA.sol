// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title FractionalRWA
 * @dev Represents a tokenized real-world asset (RWA) sold in fractional shares.
 *      Users can purchase RWA shares using a base currency (e.g. SolichainToken).
 *      Supports controlled minting, metadata anchoring, pricing, and future expansion.
 */
contract FractionalRWA is ERC20, Ownable, ReentrancyGuard {
    /// @notice Address of the accepted payment token (e.g. SolichainToken)
    address public paymentToken;

    /// @notice Price per RWA share (1 RWA = X payment tokens, e.g. 1 = 10e18 SCT)
    uint256 public sharePrice;

    /// @notice Maximum number of shares available for sale
    uint256 public maxSupply;

    /// @notice Total shares sold (minted)
    uint256 public totalSold;

    /// @notice Metadata URI describing the real-world asset (e.g., PDF, IPFS JSON)
    string public metadataURI;

    /// @notice Event emitted when a user purchases RWA shares
    event SharesPurchased(
        address indexed buyer,
        uint256 amount,
        uint256 totalCost
    );

    /**
     * @notice Initializes the RWA token contract
     * @param name Name of the ERC20 token (e.g., "Breaven Haward Realty")
     * @param symbol Symbol of the token (e.g., "BHRWA")
     * @param _paymentToken Address of the token used for payment (SolichainToken)
     * @param _sharePrice Price per share in paymentToken (e.g., 10e18)
     * @param _maxSupply Max number of shares available
     * @param _metadataURI Metadata URI describing the RWA
     */
    constructor(
        string memory name,
        string memory symbol,
        address _paymentToken,
        uint256 _sharePrice,
        uint256 _maxSupply,
        string memory _metadataURI
    ) ERC20(name, symbol) {
        require(_paymentToken != address(0), "Invalid payment token");
        require(_sharePrice > 0, "Share price must be > 0");
        require(_maxSupply > 0, "Max supply must be > 0");

        paymentToken = _paymentToken;
        sharePrice = _sharePrice;
        maxSupply = _maxSupply;
        metadataURI = _metadataURI;
    }

    /**
     * @notice Buy fractional shares of the RWA using payment token
     * @param amount Number of shares to purchase
     */
    function buyShares(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(totalSold + amount <= maxSupply, "Exceeds max supply");

        uint256 cost = amount * sharePrice;

        bool success = IERC20(paymentToken).transferFrom(
            msg.sender,
            address(this),
            cost
        );
        require(success, "Payment transfer failed");

        _mint(msg.sender, amount);
        totalSold += amount;

        emit SharesPurchased(msg.sender, amount, cost);
    }

    /**
     * @notice Returns the total cost to purchase a given number of shares
     * @param amount Number of shares
     */
    function quote(uint256 amount) external view returns (uint256) {
        return amount * sharePrice;
    }

    /**
     * @notice Update the metadata URI (e.g., for due diligence, legal docs)
     * @param newURI New metadata URI string
     */
    function setMetadataURI(string memory newURI) external onlyOwner {
        metadataURI = newURI;
    }

    /**
     * @notice Emergency withdrawal by owner (e.g., collected funds to RWA custodian)
     * @param to Address to receive funds
     * @param amount Amount of payment token to transfer
     */
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(IERC20(paymentToken).transfer(to, amount), "Withdraw failed");
    }

    /**
     * @notice Returns current RWA metadata URI
     */
    function getMetadataURI() external view returns (string memory) {
        return metadataURI;
    }
}
