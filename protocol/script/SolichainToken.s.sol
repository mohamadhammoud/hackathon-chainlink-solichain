// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/cross-chain-erc20/SolichainToken.sol";

contract DeploySolichainToken is Script {
    function run() external {
        // Load environment variables
        string memory privateKey = vm.envString("PRIVATE_KEY");

        // Convert private key string to uint256
        uint256 pk = vm.parseUint(privateKey);

        // Set the deployer's private key
        vm.startBroadcast(pk);

        // Define constructor parameters
        // uint256 initialSupply = 1_000_000_000_000000000000000000;
        // address router = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59; // router Ethereum sepolia, you can get it from Helper.sol
        // address link = 0x779877A7B0D9E8603169DdbD7836e478b4624789; // https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#ethereum-sepolia-base-sepolia

        uint256 initialSupply = 0;
        address router = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93; // router Base sepolia, you can get it from Helper.sol
        address link = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410; // https://docs.chain.link/resources/link-token-contracts

        // Deploy the SolichainToken contract
        SolichainToken token = new SolichainToken(initialSupply, router, link);

        vm.stopBroadcast();

        // Output the deployed contract address
        console.log("SolichainToken deployed at:", address(token));
        console.log(
            "My balance is:",
            token.balanceOf(0x85dA99c8a7C2C95964c8EfD687E95E632Fc533D6)
        );
    }
}

// deploying on ethereum sepolia
// forge script script/SolichainToken.s.sol --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
// ##### sepolia
// ✅  [Success]Hash: 0x06ed99a8beb6d38ff862294c64de092079d8bd8ec130ba9e0d9ac924a5a0e919
// Contract Address: 0xBD1e6CB60c174d69cAAC4Be32CeC3CbCBFd80F16
// Block: 6733498
// Paid: 0.037717886021221278 ETH (1688553 gas * 22.337401326 gwei)

// flatten the contract
// forge flatten src/cross-chain-erc20/SolichainToken.sol --output flattened/SolichainToken.sol

// since we do need to verify the contract, we do need to cast the parameters that we passed when we deployed.
// parameters: 1000000000000000000000000000 "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59" "0x779877A7B0D9E8603169DdbD7836e478b4624789"
// the command: cast abi-encode "constructor(uint256,address,address)" 1000000000000000000000000000 "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59" "0x779877A7B0D9E8603169DdbD7836e478b4624789"
// output: 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce80000000000000000000000000000000bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59000000000000000000000000779877a7b0d9e8603169ddbd7836e478b4624789

// verify contract
// forge verify-contract --chain-id 11155111 --num-of-optimizations 200 --compiler-version v0.8.19 --watch "0xBD1e6CB60c174d69cAAC4Be32CeC3CbCBFd80F16" "src/cross-chain-erc20/SolichainToken.sol:SolichainToken" --etherscan-api-key "PUT YOUR ETHER SCAN API VALUE HERE" --constructor-args 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce80000000000000000000000000000000bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59000000000000000000000000779877a7b0d9e8603169ddbd7836e478b4624789

// deploying on ethereum sepolia
// forge script script/SolichainToken.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

//  base-sepolia
// ✅  [Success]Hash: 0xa39568d1ee91455c20bdea262b6f4330b815607ddb6ddd1142d31db7a13d0f17
// Contract Address: 0x6FdA56C57B0Acadb96Ed5624aC500C0429d59429
// Block: 15581090
// Paid: 0.00000164907035041 ETH (1648645 gas * 0.001000258 gwei)

// flatten the contract note: since you are using the same contract you can skip the flatten because you made it before.
// forge flatten src/cross-chain-erc20/SolichainToken.sol --output flattened/SolichainToken.sol

// since we do need to verify the contract, we do need to cast the parameters that we passed when we deployed.
// cast abi-encode "constructor(uint256,address,address)" 0  "0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93" "0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
// 0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d3b06cebf099ce7da4accf578aaebfdbd6e88a93000000000000000000000000e4ab69c077896252fafbd49efd26b5d171a32410

// just as note for base sepolia login my username is: mohamadhammoud98

// 1000000000000000000000
