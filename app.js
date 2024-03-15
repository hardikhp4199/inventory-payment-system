window.addEventListener('load', async () => {
  // Connect to Ethereum blockchain using Web3.js
  if (window.ethereum) {
    window.web3 = new Web3(window.ethereum);
    try {
      // Request account access if needed
      await window.ethereum.enable();
      console.log("Connected to Ethereum blockchain!");
    } catch (error) {
      console.error("User denied account access:", error);
    }
  } else if (window.web3) {
    window.web3 = new Web3(window.web3.currentProvider);
    console.log("Connected to Ethereum blockchain!");
  } else {
    console.error("Non-Ethereum browser detected. You should consider trying MetaMask!");
  }

  // Contract ABI (paste ABI generated from compilation)
  const contractABI = [/* Paste ABI here */];
  // Contract address (paste deployed contract address)
  const contractAddress = '0x...';

  // Initialize contract object
  const contract = new web3.eth.Contract(contractABI, contractAddress);

  // Example function to interact with the contract
  async function placeOrder() {
    const productName = document.getElementById('productName').value;
    const productQty = parseInt(document.getElementById('productQty').value);
    const productPrice = parseInt(document.getElementById('productPrice').value);

    // Example: Call smart contract function to place order
    await contract.methods.placeOrder([{
      productName: productName,
      productQtyOrder: productQty,
      productPrice: productPrice
    }]).send({ from: web3.eth.defaultAccount });
  }

  // Example event listener for form submission
  document.getElementById('orderForm').addEventListener('submit', async (event) => {
    event.preventDefault();
    await placeOrder();
  });
});
