// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract InventoryPayment {
    struct Order {
        uint256 orderNo;
        uint256 orderDate;
        uint256 orderTotalAmount;
        bool orderStatus;
        mapping(uint256 => OrderDetail) orderDetails; // Mapping product IDs to OrderDetail structs
    }

    struct Product {
        uint256 productId;
        string productName;
        uint256 productPrice;
        uint256 productQty;
    }

    struct OrderDetail {
        uint256 productId;
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
    uint256 public orderCount;
    
    mapping(uint256 => Product) public products;
    mapping(address => Order[]) public userOrders;
    mapping(address => Bank) public userBankDetails;

    event OrderPlaced(uint256 indexed orderNo, address indexed user);
    event ProductAdded(uint256 indexed productId);
    event ProductUpdated(uint256 indexed productId);
    event ProductDeleted(uint256 indexed productId);
    event PaymentSent(uint256 indexed orderNo, address indexed supplier, uint256 amount);

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

    // Function to add user bank details
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

    // Function to place an order
    function placeOrder(uint256[] memory _productIds, uint256[] memory _productQtyOrder) external {
        require(_productIds.length == _productQtyOrder.length, "Length mismatch");
        
        uint256 totalAmount = 0;
        OrderDetail[] memory orderDetails = new OrderDetail[](_productIds.length);
        for (uint256 i = 0; i < _productIds.length; i++) {
            require(_productIds[i] <= productCount && _productIds[i] > 0, "Invalid product ID");
            Product storage product = products[_productIds[i]];
            require(product.productQty >= _productQtyOrder[i], "Insufficient product quantity");
            totalAmount += product.productPrice * _productQtyOrder[i];
            orderDetails[i] = OrderDetail(_productIds[i], _productQtyOrder[i], 0); // Initialize received quantity as 0
            product.productQty -= _productQtyOrder[i]; // Update product quantity
        }
        
        require(totalAmount > 0, "Total amount cannot be zero");
        
        Bank storage userBank = userBankDetails[msg.sender];
        require(userBank.bankAccountNumber != 0, "Bank details not added");
        require(userBank.backupAmount + userBank.bankAccountNumber >= totalAmount, "Insufficient balance");
        
        orderCount++;
        uint256 orderNo = orderCount; // Use sequential order number
        Order storage newOrder = userOrders[msg.sender].push();
        newOrder.orderNo = orderNo;
        newOrder.orderDate = block.timestamp;
        newOrder.orderTotalAmount = totalAmount;
        newOrder.orderStatus = false;
        
        for (uint256 i = 0; i < orderDetails.length; i++) {
            newOrder.orderDetails[orderDetails[i].productId] = orderDetails[i];
        }
        
        emit OrderPlaced(orderNo, msg.sender);
    }


 // Function to mark an order as received
function receiveOrder(uint256 _orderNo) external {
    Order[] storage orders = userOrders[msg.sender];
    bool orderFound = false;
    for (uint256 i = 0; i < orders.length; i++) {
        if (orders[i].orderNo == _orderNo && !orders[i].orderStatus) {
            orders[i].orderStatus = true;
            for (uint256 productId = 1; productId <= productCount; productId++) {
                if (orders[i].orderDetails[productId].productId != 0) {
                    orders[i].orderDetails[productId].productQtyReceived = orders[i].orderDetails[productId].productQtyOrder;
                }
            }
            orderFound = true;
            break;
        }
    }
    require(orderFound, "Order not found or already received");
}



    // Function to pay a supplier for a received order
    function paySupplier(uint256 _orderNo) external {
        Order[] storage orders = userOrders[msg.sender];
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].orderNo == _orderNo && orders[i].orderStatus) {
                uint256 totalAmount = orders[i].orderTotalAmount;
                Bank storage userBank = userBankDetails[msg.sender];
                require(userBank.backupAmount + userBank.bankAccountNumber >= totalAmount, "Insufficient balance");

                // Logic to transfer funds to supplier's account
                // Assuming funds transfer logic is implemented elsewhere
                
                // Updating user's bank balance
                userBank.backupAmount -= totalAmount;
                emit PaymentSent(_orderNo, msg.sender, totalAmount);
                break;
            }
        }
    }
}
