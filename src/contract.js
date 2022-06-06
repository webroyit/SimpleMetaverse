// Connection to the blockchain

import abi from "./abi/abi.json" assert {type: "json"};

export let web3;
export let contract;

export const connect = new Promise((res, rej) => {
    if(typeof window.ethereum == "undefined") {
        rej("Install Metamask");
    }
    window.ethereum.request({ method: "eth_requestAccounts" });
    
    // Create web3 instance
    // It takes in a provider. (MetaMask Provider)
    web3 = new Web3(window.ethereum);

    // Instantiate NFT contract
    // It takes in Contract ABI and Address
    contract = new web3.eth.Contract(abi, "0x7c53Ef98D49eef0dd8F10dbFeF21f97AE0434A26");

    // Get ETH address
    web3.eth.getAccounts().then((accounts) => {
        contract.methods
            .totalSupply()
            .call({ from: accounts[0]})
            .then((supply) => {
                contract.methods
                    .getBuilding()
                    .call({ from: accounts[0]})
                    .then((data) => {
                        res({ supply, buildings: data});
                    })
            })
    })
})