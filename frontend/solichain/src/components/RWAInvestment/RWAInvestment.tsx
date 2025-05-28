"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { InputNumber, notification } from "antd";
import { useAppKitAccount, useAppKitNetwork, useAppKitState } from "@reown/appkit/react";
import { networks } from "@/config";

// Replace with your actual deployed addresses
const SCT_ADDRESS = "0xYourSCTonBaseSepolia";
const RWA_CONTRACT_ADDRESS = "0xYourRWAContractAddress";

const SCT_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
];

const RWA_ABI = [
  "function getSharePrice() view returns (uint256)",
  "function buyShares(uint256 sctAmount) external",
];

export default function RWAInvestment() {
  const [balance, setBalance] = useState("0");
  const [price, setPrice] = useState("0");
  const [amount, setAmount] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);

  const { address, isConnected } = useAppKitAccount();
  const { switchNetwork } = useAppKitNetwork();
  const state = useAppKitState();

  useEffect(() => {
    if (isConnected && !state.selectedNetworkId?.includes(networks[1].id as string)) {
      switchNetwork(networks[1]); // Base Sepolia
    }
  }, [isConnected]);

  useEffect(() => {
    async function loadData() {
      try {
       
      } catch (err) {
        console.error(err);
        notification.error({ message: "Error loading balance or price" });
      }
    }

    loadData();
  }, [address]);

  const handleBuy = async () => {
    try {
      if (!amount || isNaN(+amount)) {
        notification.warning({ message: "Enter a valid SCT amount" });
        return;
      }

      setLoading(true);
   

      notification.success({ message: `Successfully bought shares with ${amount} SCT!` });
      setAmount(null);
    } catch (err) {
      console.error(err);
      notification.error({ message: "Transaction failed" });
    } finally {
      setLoading(false);
    }
  };

  const getQuote = () => {
    if (!amount || !price) return "0";
    const shares = +amount / +price;
    return shares.toFixed(4);
  };

  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-xl font-semibold">🏡 RWA Investment</h2>

      <div className="text-sm text-gray-700">
        <strong>Wallet:</strong> {address || "Not connected"}
      </div>
      <div className="text-sm text-gray-700">
        <strong>SCT Balance:</strong> {balance} SCT
      </div>
      <div className="text-sm text-gray-700">
        <strong>Share Price:</strong> {price} SCT
      </div>

      <InputNumber
        value={amount}
        onChange={setAmount}
        min={0}
        step={0.01}
        placeholder="Amount in SCT"
        className="w-full max-w-xs"
        controls={false}
      />

      <div className="text-sm text-gray-500">
        🧮 Estimated Shares: <strong>{getQuote()}</strong>
      </div>

      <button
        onClick={handleBuy}
        disabled={loading}
        className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 w-fit"
      >
        {loading ? "Buying..." : "Buy Shares"}
      </button>
    </div>
  );
}
