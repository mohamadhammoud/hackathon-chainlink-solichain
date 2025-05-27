// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/RWA/FractionalRWA.sol";

contract DeployRWA is Script {
    function run() external {
        // Load environment variables
        string memory privateKey = vm.envString("PRIVATE_KEY");

        // Convert private key string to uint256
        uint256 pk = vm.parseUint(privateKey);

        // Set the deployer's private key
        vm.startBroadcast(pk);

        // Define constructor parameters
        string memory name = "Breaven Haward Realty";
        string memory symbol = "BHRWA";
        address _paymentToken = 0x926d672c8453c6BC85b19A15b48F3B1530b4bf29;
        uint256 _sharePrice = 1;
        uint256 _maxSupply = 1_000_000_000_000_000000000000000000;
        string memory _metadataURI = "https://www.brevanhoward.com/";

        // Deploy the rwa contract
        FractionalRWA rwa = new FractionalRWA(
            name,
            symbol,
            _paymentToken,
            _sharePrice,
            _maxSupply,
            _metadataURI
        );

        vm.stopBroadcast();

        // Output the deployed contract address
        console.log("Breaven Haward Realty deployed at:", address(rwa));
    }
}

// deploying on base sepolia
// forge script script/RWA.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

// flatten the contract note: since you are using the same contract you can skip the flatten because you made it before.
// forge flatten src/cross-chain-erc20/SolichainToken.sol --output flattened/SolichainToken.sol
