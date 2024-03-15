// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract InventoryPayment {
    struct Order {
        uint256 orderNo;
        uint256 orderDate;
        uint256 orderTotalAmount;
        bool orderStatus;
        uint256[] orderProductIds; // Storing product IDs instead of entire structs
        mapping(uint256 => Product) orderDetails; // Mapping product IDs to Product structs
    }

    struct Product {
        uint256 productId;
        string productName;
        uint256 productPrice;
        uint256 productQtyOrder;
        uint256 productQtyReceived;
    }

    struct Bank {
        uint256 id;
        string bankName;
        uint256 bankAccountNumber;
        uint256 backupAmount;
    }
    uint256 public productCount;

    mapping(uint256 => Product) public products;
    mapping(address => Order[]) public userOrders;
    mapping(address => Bank) public userBankDetails;

    event OrderPlaced(uint256 indexed orderNo, address indexed user);
    event ProductAdded(uint256 indexed productId);
    event ProductUpdated(uint256 indexed productId);
    event ProductDeleted(uint256 indexed productId);

    function placeOrder(Product[] memory _products) external {
        uint256 totalAmount = 0;
        uint256[] memory productIds = new uint256[](_products.length); // Define productIds array
        for (uint256 i = 0; i < _products.length; i++) {
            totalAmount += _products[i].productPrice * _products[i].productQtyOrder;
            uint256 productId = block.timestamp + i; // Generate unique product ID
            productIds[i] = productId; // Store product ID
            userOrders[msg.sender][userOrders[msg.sender].length - 1].orderDetails[productId] = _products[i]; // Store product in orderDetails mapping
        }
        require(totalAmount > 0, "Total amount cannot be zero");
        
        Bank storage userBank = userBankDetails[msg.sender];
        require(userBank.bankAccountNumber != 0, "Bank details not added");
        require(userBank.backupAmount + userBank.bankAccountNumber >= totalAmount, "Insufficient balance");
        
        Order[] storage userOrderList = userOrders[msg.sender];
        userOrderList.push(); // Push an empty order
        Order storage newOrder = userOrderList[userOrderList.length - 1]; // Get reference to the new order
        newOrder.orderNo = block.timestamp; // Use timestamp as order number
        newOrder.orderDate = block.timestamp;
        newOrder.orderTotalAmount = totalAmount;
        newOrder.orderStatus = false;
        newOrder.orderProductIds = productIds;
        
        emit OrderPlaced(newOrder.orderNo, msg.sender);
    }


    function receiveOrder(uint256 _orderNo) external {
        Order[] storage orders = userOrders[msg.sender];
        bool orderFound = false;
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].orderNo == _orderNo && !orders[i].orderStatus) {
                orders[i].orderStatus = true;
                uint256[] storage productIds = orders[i].orderProductIds; // Get product IDs
                for (uint256 j = 0; j < productIds.length; j++) {
                    uint256 productId = productIds[j];
                    orders[i].orderDetails[productId].productQtyReceived = orders[i].orderDetails[productId].productQtyOrder;
                }
                orderFound = true;
                break;
            }
        }
        require(orderFound, "Order not found or already received");
    }


    function paySupplier(uint256 _orderNo) external view {
        Order[] storage orders = userOrders[msg.sender];
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].orderNo == _orderNo && orders[i].orderStatus) {
                // Logic to transfer funds to supplier's account
                // Assuming funds transfer logic is implemented elsewhere
                break;
            }
        }
    }

    function addUserBankDetails(
        string memory _bankName,
        uint256 _bankAccountNumber,
        uint256 _backupAmount
    ) external {
        require(
            bytes(userBankDetails[msg.sender].bankName).length == 0,
            "Bank details already added"
        );

        Bank memory newUserBankDetails;
        newUserBankDetails.id = block.timestamp; // Use timestamp as bank id
        newUserBankDetails.bankName = _bankName;
        newUserBankDetails.bankAccountNumber = _bankAccountNumber;
        newUserBankDetails.backupAmount = _backupAmount;

        userBankDetails[msg.sender] = newUserBankDetails;
    }

    // Function to add a new product
    function addProduct(string memory _productName, uint256 _productPrice, uint256 _productQty) external {
        productCount++;
        products[productCount] = Product(productCount, _productName, _productPrice, _productQty);
        emit ProductAdded(productCount);
    }

    // Function to view details of a specific product
    function viewProduct(uint256 _productId) external view returns (
        string memory productName,
        uint256 productPrice,
        uint256 productQty
    ) {
        require(_productId <= productCount && _productId > 0, "Invalid product ID");
        Product memory product = products[_productId];
        return (product.productName, product.productPrice, product.productQty);
    }

    // Function to update details of a product
    function updateProduct(uint256 _productId, string memory _newName, uint256 _newPrice, uint256 _newQty) external {
        require(_productId <= productCount && _productId > 0, "Invalid product ID");
        Product storage product = products[_productId];
        product.productName = _newName;
        product.productPrice = _newPrice;
        product.productQty = _newQty;
        emit ProductUpdated(_productId);
    }

    // Function to delete a product
    function deleteProduct(uint256 _productId) external {
        require(_productId <= productCount && _productId > 0, "Invalid product ID");
        delete products[_productId];
        emit ProductDeleted(_productId);
    }

    // Function to view all products
    function viewAllProducts() external view returns (Product[] memory) {
        Product[] memory allProducts = new Product[](productCount);
        for (uint256 i = 1; i <= productCount; i++) {
            allProducts[i - 1] = products[i];
        }
        return allProducts;
    }
}
