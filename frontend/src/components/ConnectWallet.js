import React, { useEffect, useState, createContext, useContext } from "react";
import Web3 from "web3";
import NFTMintDN404 from "../contracts/NFTMintDN404.json";
import NFTMarketplaceABI from "../contracts/NFTMarketplace.json";

// Create a context for Web3
const Web3Context = createContext();

// Custom hook to use the Web3 context
export const useWeb3 = () => useContext(Web3Context);

function ConnectWallet({ children }) {
  const [web3, setWeb3] = useState(null);
  const [signer, setSigner] = useState(null);
  const [nftContract, setNftContract] = useState(null);
  const [account, setAccount] = useState(null);
  const [marketplaceContract, setMarketplaceContract] = useState(null);

  const marketplaceAddress = "0xAf54A12C4535a5b7e735E040C5AaD21fEB1AE771";
  const nftContractAddress = "0x57ec31e7c387dA14978B2C9D1E6619C6Ae7cf840";

  useEffect(() => {
    if (window.ethereum) {
      const web3Instance = new Web3(window.ethereum);
      setWeb3(web3Instance);
    }
  }, []);

  const connectWallet = async () => {
    if (web3) {
      try {
        const accounts = await web3.eth.getAccounts();
        const account = accounts[0];
        console.log(account);
        const marketplaceContract = new web3.eth.Contract(
          NFTMarketplaceABI.abi,
          marketplaceAddress
        );
        const tokenContract = new web3.eth.Contract(
          NFTMintDN404.abi,
          nftContractAddress
        );
        setMarketplaceContract(marketplaceContract);
        setNftContract(tokenContract);
        setAccount(account);
        // Set default account
        marketplaceContract.options.from = account;
        tokenContract.options.from = account;
      } catch (error) {
        console.error(error);
      }
    }
  };

  const disconnectWallet = () => {
    setAccount(null);
    setMarketplaceContract(null);
    setNftContract(null);
  };

  return (
    <Web3Context.Provider
      value={{
        web3,
        signer,
        nftContract,
        account,
        marketplaceContract,
        marketplaceAddress,
        nftContractAddress,
        disconnectWallet,
        connectWallet,
      }}
    >
      <div>{children}</div>
    </Web3Context.Provider>
  );
}

export default ConnectWallet;
