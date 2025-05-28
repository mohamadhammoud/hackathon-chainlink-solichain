"use client";

import { useEffect, useState } from "react";
import { BrowserProvider, Contract, Eip1193Provider, formatUnits, parseEther, parseUnits } from "ethers";
import { InputNumber, notification } from "antd";
import { useAppKitAccount, useAppKitNetwork, useAppKitProvider, useAppKitState } from "@reown/appkit/react";
import { networks } from "@/config";

// Replace with your actual deployed addresses
const SCT_ADDRESS = "0x926d672c8453c6BC85b19A15b48F3B1530b4bf29";
const RWA_CONTRACT_ADDRESS = "0x1db6B964c3056539B72C60bB38400FA844107415";

const SCT_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
];

const RWA_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function sharePrice() view returns (uint256)",
  "function quote(uint256 amount) external view returns (uint256)",
  "function buyShares(uint256 sctAmount) external",
];

export default function RWAInvestment() {
  const [stcBalance, setSTCBalance] = useState("0");
  const [rwaBalance, setRWABalance] = useState("0");
  const [sharePrice, setSharePrice] = useState("0");
  const [quote, setQuote] = useState("0");
  const [amount, setAmount] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);

  const { address, isConnected } = useAppKitAccount();
  const { switchNetwork } = useAppKitNetwork();
  const { walletProvider } = useAppKitProvider("eip155");
  const state = useAppKitState();

  useEffect(() => {
    if (isConnected && !state.selectedNetworkId?.includes(networks[1].id as string)) {
      switchNetwork(networks[1]); // Base Sepolia
    }

      // get SCT balance
      async function loadSTCBalance() {  
        const ethersProvider = new BrowserProvider(walletProvider as Eip1193Provider);
        // const signer = await ethersProvider.getSigner();
  
        // The Contract object
        const solichainTokenContract = new Contract(SCT_ADDRESS, SCT_ABI, ethersProvider);
        const solichainTokenBalance = await solichainTokenContract.balanceOf(address);
        
        setSTCBalance(() => formatUnits(solichainTokenBalance, 18));
      }

      // get SCT balance
      async function loadRWABalance() {  
        const ethersProvider = new BrowserProvider(walletProvider as Eip1193Provider);
        // const signer = await ethersProvider.getSigner();
  
        // The Contract object
        const rwaTokenContract = new Contract(RWA_CONTRACT_ADDRESS, RWA_ABI, ethersProvider);
        const rwaBalance = await rwaTokenContract.balanceOf(address);
        
        setRWABalance(() => formatUnits(rwaBalance, 18));
      }

      async function loadSharePrice () {
        const ethersProvider = new BrowserProvider(walletProvider as Eip1193Provider);
        // const signer = await ethersProvider.getSigner();
  
        // The Contract object
        const rwaTokenContract = new Contract(RWA_CONTRACT_ADDRESS, RWA_ABI, ethersProvider);
        const price = await rwaTokenContract.sharePrice();
        
        setSharePrice(() => price);
      };
  
      if(isConnected && state.selectedNetworkId?.includes(networks[1].id as string)) {
        loadSTCBalance();
        loadRWABalance();
        loadSharePrice();
      }

  }, [isConnected]);

  useEffect(() => {
    async function loadQuote() {
      try {
        if (
          !walletProvider ||
          amount === null ||
          isNaN(+amount) ||
          +amount <= 0
        ) {
          return;
        }
  
        const ethersProvider = new BrowserProvider(walletProvider as Eip1193Provider);
        const rwaTokenContract = new Contract(RWA_CONTRACT_ADDRESS, RWA_ABI, ethersProvider);
  
        // 👇 convert amount to BigNumber (wei)
        const amountInWei = parseEther(amount.toString());
        const quoted = await rwaTokenContract.quote(amountInWei);
          console.log({quoted})
        setQuote(() => formatUnits(quoted, 18)); // or just quoted.toString()
      } catch (err) {
        console.error("Quote failed", err);
        notification.error({ message: "Could not get quote" });
      }
    }
  
    if (isConnected && amount !== null) {
      loadQuote();
    }
  }, [isConnected, amount]);
  

  const handleBuy = async () => {
    try {
      if (!amount || isNaN(+amount)) {
        notification.warning({ message: "Enter a valid SCT amount" });
        return;
      }

      if(isConnected) {
        setLoading(true);

        const ethersProvider = new BrowserProvider(walletProvider as Eip1193Provider);
        const signer = await ethersProvider.getSigner();
        
        const amountInWei = parseEther(amount);

        const solichainTokenContract = new Contract(SCT_ADDRESS, SCT_ABI, signer);
        const approvalTx = await solichainTokenContract.approve(RWA_CONTRACT_ADDRESS, amountInWei);
        await approvalTx.wait();

        // The Contract object
        const rwaTokenContract = new Contract(RWA_CONTRACT_ADDRESS, RWA_ABI, signer);
        const buySharesTx = await rwaTokenContract.buyShares(amountInWei);
        await buySharesTx.wait();

        setLoading(false);
      }
   

      notification.success({ message: `Successfully bought shares with ${amount} SCT!` });
      setAmount(null);
    } catch (err) {
      console.error(err);
      notification.error({ message: "Transaction failed" });
    } finally {
      setLoading(false);
    }
  };

 

  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-xl font-semibold">🏡 RWA Investment</h2>

      <div className="text-sm text-gray-700">
        <strong>Wallet:</strong> {address || "Not connected"}
      </div>
      <div className="text-sm text-gray-700">
        <strong>SCT Balance:</strong> {stcBalance} SCT
      </div>
      <div className="text-sm text-gray-700">
        <strong>BHRWA token Balance:</strong> {rwaBalance} BHRWA
      </div>
      <div className="text-sm text-gray-700">
        <strong>Share Price:</strong> {sharePrice} SCT
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

<div className="text-sm text-gray-600 leading-5">
  🧮 You will receive approximately <strong className="text-black">{quote} RWA shares </strong> 
  for your input of <strong className="text-black">{amount} SCT</strong>, 
  based on the current share price of <strong className="text-black">{sharePrice} SCT</strong> per share.
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
