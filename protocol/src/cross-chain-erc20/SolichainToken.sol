// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Solichain Token
 * @dev An ERC20 token that supports cross-chain transfers using Chainlink CCIP.
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract SolichainToken is ERC20, CCIPReceiver, Ownable {
    /// @notice Mapping to track locked tokens on the source chain
    mapping(address => uint256) public lockedBalances;

    /// @notice Mapping to store the parallel token contract addresses on multiple chains
    mapping(uint64 => address) public parallelTokenAddresses;

    /// @notice Link token interface to handle LINK token interactions
    LinkTokenInterface public linkToken;

    /// @notice Emitted when a cross-chain transfer is initiated
    /// @param sender The address initiating the transfer
    /// @param destinationChain The chain ID of the destination chain
    /// @param amount The amount of tokens being transferred
    event CrossChainTransfer(
        address indexed sender,
        uint64 destinationChain,
        uint256 amount
    );

    /// @notice Emitted when a parallel token address is set for a chain
    /// @param chainId The chain ID for which the parallel token address is set
    /// @param newParallelTokenAddress The address of the parallel token contract on the specified chain
    event ParallelTokenAddressSet(
        uint64 indexed chainId,
        address indexed newParallelTokenAddress
    );

    /**
     * @notice Constructor for the CrossChainToken
     * @param initialSupply The initial supply of tokens to mint to the deployer
     * @param router The address of the Chainlink CCIP Router contract
     * @param link The address of the LINK token contract
     */
    constructor(
        uint256 initialSupply,
        address router,
        address link
    ) ERC20("Solichain Token", "SCT") CCIPReceiver(router) {
        _mint(msg.sender, initialSupply);
        linkToken = LinkTokenInterface(link);
    }

    /**
     * @notice Sets the parallel token contract address for a specific chain
     * @param chainId The chain ID of the target chain
     * @param _parallelTokenAddress The address of the parallel token contract on the target chain
     */
    function setParallelTokenAddress(
        uint64 chainId,
        address _parallelTokenAddress
    ) external onlyOwner {
        parallelTokenAddresses[chainId] = _parallelTokenAddress;
        emit ParallelTokenAddressSet(chainId, _parallelTokenAddress);
    }

    /**
     * @notice Locks tokens and initiates a cross-chain transfer to the destination chain
     * @param destinationChain The chain ID of the destination chain
     * @param amount The amount of tokens to transfer
     */
    function lockTokens(uint64 destinationChain, uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Not enough tokens");
        require(
            parallelTokenAddresses[destinationChain] != address(0),
            "Parallel token address not set for destination chain"
        );

        // Lock tokens
        _transfer(msg.sender, address(this), amount);
        lockedBalances[msg.sender] += amount;

        // Send cross-chain message
        _sendCrossChainMessage(destinationChain, amount);
        emit CrossChainTransfer(msg.sender, destinationChain, amount);
    }

    /**
     * @notice Burns tokens on the destination chain to unlock tokens on the source chain
     * @param amount The amount of tokens to burn
     * @param sourceChain The chain ID of the source chain where tokens will be unlocked
     */
    function burnTokens(uint256 amount, uint64 sourceChain) external {
        require(balanceOf(msg.sender) >= amount, "Not enough tokens");
        require(
            parallelTokenAddresses[sourceChain] != address(0),
            "Parallel token address not set for source chain"
        );

        // Burn tokens
        _burn(msg.sender, amount);

        // Send cross-chain message to unlock tokens on the source chain
        _sendCrossChainMessage(sourceChain, amount);
    }

    /**
     * @notice Mint new Solichain tokens to the caller's address.
     * @dev This function is public and intended for testing purposes only.
     *      It allows anyone to mint arbitrary amounts of Solichain tokens on testnets.
     *      In production deployments, this function should be restricted or removed.
     * @param amount The amount of tokens to mint, denominated in wei (e.g., 1000 * 10**18).
     * @custom:danger This function is unrestricted and should NOT be included in mainnet deployments.
     */
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    /**
     * @notice Withdraws LINK tokens (used for paying CCIP fees) to the contract owner
     * @param amount The amount of LINK tokens to withdraw
     */
    function withdrawLink(uint256 amount) external onlyOwner {
        require(
            linkToken.balanceOf(address(this)) >= amount,
            "Not enough LINK tokens"
        );
        linkToken.transfer(msg.sender, amount);
    }

    /**
     * @notice Retrieves the required LINK fee for a cross-chain message
     * @param destinationChain The chain ID of the destination chain
     * @param amount The amount of tokens to transfer
     * @return fees The amount of LINK tokens required as a fee
     */
    function getRequiredFee(
        uint64 destinationChain,
        uint256 amount
    ) external view returns (uint256 fees) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(parallelTokenAddresses[destinationChain]),
            data: abi.encode(msg.sender, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(linkToken)
        });

        IRouterClient router = IRouterClient(getRouter());
        fees = router.getFee(destinationChain, message);
    }

    /**
     * @notice External getter function to retrieve the locked balance of an address
     * @param account The address for which to retrieve the locked balance
     * @return The amount of tokens locked for the given address
     */
    function getLockedBalance(address account) external view returns (uint256) {
        return lockedBalances[account];
    }

    /**
     * @notice External getter function to retrieve the parallel token address for a chain
     * @param chainId The chain ID for which to retrieve the parallel token address
     * @return The address of the parallel token contract on the specified chain
     */
    function getParallelTokenAddress(
        uint64 chainId
    ) external view returns (address) {
        return parallelTokenAddresses[chainId];
    }

    /**
     * @notice Internal function to send a cross-chain message via Chainlink CCIP
     * @param destinationChain The chain ID of the destination chain
     * @param amount The amount of tokens being transferred
     */
    function _sendCrossChainMessage(
        uint64 destinationChain,
        uint256 amount
    ) internal {
        // Prepare the cross-chain message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(parallelTokenAddresses[destinationChain]),
            data: abi.encode(msg.sender, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(linkToken)
        });

        IRouterClient router = IRouterClient(getRouter());
        uint256 fees = router.getFee(destinationChain, message);

        // Approve the Router to spend LINK tokens for the fee
        linkToken.approve(address(router), fees);

        // Send the cross-chain message
        router.ccipSend(destinationChain, message);
    }

    /**
     * @notice Internal function called by the CCIP Router to handle incoming cross-chain messages
     * @param any2EvmMessage The incoming cross-chain message
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        (address sender, uint256 amount) = abi.decode(
            any2EvmMessage.data,
            (address, uint256)
        );

        _mint(sender, amount);
    }
}
