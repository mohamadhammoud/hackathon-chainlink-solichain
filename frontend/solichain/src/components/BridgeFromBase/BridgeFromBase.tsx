"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { InputNumber, notification } from "antd";
import {  useAppKitAccount, useAppKitNetwork, useAppKitState  } from '@reown/appkit/react'
import { networks } from '@/config'

// Replace with your deployed SolichainToken address on Base Sepolia
const SOLICHAIN_TOKEN_ADDRESS = "0xYourSepoliaSCTAddress";
const SOLICHAIN_TOKEN_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function lockTokens(uint64 destinationChain, uint256 amount) external",
];

const BASE_CHAIN_SELECTOR = 84532; // Chainlink CCIP selector for Base Sepolia

export default function BridgeFromBase() {
  const [balance, setBalance] = useState("0");
  const [amount, setAmount] =useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [walletAddress, setWalletAddress] = useState("");

  const { switchNetwork } = useAppKitNetwork();
  const {address, caipAddress, isConnected, embeddedWalletInfo} = useAppKitAccount();

  const state = useAppKitState();
  console.log({state})

  useEffect(() => {


    if(isConnected && !state.selectedNetworkId?.includes(networks[1].id as string)) {
        switchNetwork(networks[1])
    }
}, [isConnected]);

  // Connect to Metamask and get SCT balance
  useEffect(() => {
    async function loadBalance() {
   
    }

    loadBalance();
  }, []);

  const handleBridge = async () => {
    try {
      if (!amount || isNaN(+amount)) {
        notification.warning({ message: "Enter a valid amount" });
        return;
      }

      setLoading(true);
     

      notification.success({ message: `Bridged ${amount} SCT to Base Sepolia!` });
      setAmount("");
    } catch (err) {
      console.error(err);
      notification.error({ message: "Bridge failed" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-xl font-semibold">🌉 Bridge from Base Sepolia to Ethereum Sepolia</h2>

      <div className="text-sm text-gray-700">
        <strong>Wallet:</strong> {walletAddress || "Not connected"}
      </div>

      <div className="text-sm text-gray-700">
        <strong>Solichain Balance:</strong> {balance} SCT
      </div>

    


<InputNumber
  value={amount}
  onChange={setAmount}
  min={0}
  step={0.01}
  placeholder="Amount to bridge"
  className="w-full max-w-xs"
  controls={false}
/>


      <button
        onClick={handleBridge}
        disabled={loading}
        className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50 w-fit"
      >
        {loading ? "Bridging..." : "Bridge SCT → Base Sepolia"}
      </button>
    </div>
  );
}
