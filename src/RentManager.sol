// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Leaderboard.sol";

contract RentManager {
    //item struct
    struct Item {
        uint256 itemId;
        string itemName;
        uint256 itemPrice;
        uint256 prevSoldPrice;
        address owner;
        bool forsale;
    }

    // struct used to better organize an invoice
    struct Invoice {
        Item item;
        // uint256 amount;          // total amount requested by the host
        // uint256 remainingAmount; // remaining amount that the guest needs to pay; 0 means fully paid out
        address buyer;            // the buyer that sends the invoice
        // address guest;           
    }

    address private admin;        // address of admin
    uint256 private currItemId;
    // maps an address to one of the following roles:
    //   - 0: unregistered users
    //   - 1: admin, the one that deploy the contract; do not use
    //   - 2: user
    //   - others: invalid; do not use
    mapping(address => uint8) private roles;

    // maps an address to its balance
    mapping(address => uint256) private balances;

    // array of all invoices
    Invoice[] private invoices;

    // array of all items
    Item[] private items;

    
    // maps an address to its existing invoice id
    // the invoice id can be used as index to access the `invoices` array
    mapping(address => uint256) private addr2invoice;

    // maps an address to its item
    // the item id can be used as index to access the 'items' array
    mapping(uint256 => Item) private id2item;

    Leaderboard leaderboard;
    constructor(Leaderboard lboard) {
        roles[msg.sender] = 1;
        leaderboard = lboard;
        // create dummy invoice for default invoice to connect to
        currItemId = 0;
        Item memory defaultItem = Item({
            itemId: 0,
            itemName: "default",
            itemPrice: 0,
            prevSoldPrice: 0,
            owner: address(0),
            forsale: false
        });
        Invoice memory invoice = Invoice({
            item: defaultItem,
            buyer: address(0)
            //amount: 0
            //remainingAmount: 0,
        });
        invoices.push(invoice);
    }

    // Add balance to the caller's account
    // Args:
    //   - amount (uint256): the amout to add
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only registered users (admin/host/guest) add balance; otherwise, return false
    function addBalance(uint256 amount) public returns (bool) {
        // registered user only
        if (roles[msg.sender] == 1 || roles[msg.sender] == 2) {
            balances[msg.sender] += amount;
            return true;
        } else {
            return false;
        }
    }
    // Add item to the items POSTING
    // function addItem(Item calldata item) public returns (bool) {
    //     if(roles[msg.sender] == 1 || roles[msg.sender] == 2){
            
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }
    
    //add or edit item
    function postItem(uint256 itemId, string calldata itemName, uint256 itemPrice, bool forsale) public returns (bool) {
        if(roles[msg.sender] != 1 || roles[msg.sender] != 2){
            return false;
        }
        // check if the item exists yet or not
        if (itemId != 0) {
            // check if the owner of the item is the same as the one posting it
            if (msg.sender != id2item[itemId].owner){
                return false;
            }

            int discount; // used for leaderboard only
            if(itemPrice >= id2item[itemId].itemPrice) {
                discount = int(id2item[itemId].itemPrice) - int(itemPrice);
            } else {
                discount += int(id2item[itemId].itemPrice) - int(itemPrice);
            }

            Item memory item = Item({
                itemId: itemId,
                itemName: itemName,
                prevSoldPrice: id2item[itemId].prevSoldPrice,
                itemPrice: itemPrice,
                owner: address(msg.sender),
                forsale: forsale
            });
        }
        else {
            //currItemId starts at 0
            currItemId++;
            //DNE
            Item memory item = Item({
                itemId: currItemId,
                itemName: itemName,
                itemPrice: itemPrice,
                prevSoldPrice: 0,
                owner: address(msg.sender),
                forsale: forsale
            });
            items.push(item);
            id2item[item.itemId] = item;
            return true;
        }
        

        
    }

    //view items that are being sold
    function viewItems() public returns (Item[] memory) {
        Item[] storage forsaleItems;
        for(uint256 i = 0; i < items.length; i++) {
            if (items[i].forsale){
                forsaleItems.push(items[i]);
            }
        }
        return forsaleItems;
    }

    //buy an item
    function purchaseItem(uint256 itemId) public returns (bool) {
        if (roles[msg.sender] != 1 || roles[msg.sender] != 2){
            return false;
        }
        
        Item memory item = id2item[itemId];
        if (!item.forsale){
            return false;
        }
        if(item.itemPrice > balances[msg.sender]) {
            return false;
        }
        
        //buyer
        balances[invoices[addr2invoice[msg.sender]].buyer] -= item.itemPrice;
        //seller
        balances[invoices[addr2invoice[msg.sender]].item.owner] += item.itemPrice;
        // change the owner of the item
        item.owner = invoices[addr2invoice[msg.sender]].buyer;
        item.prevSoldPrice = item.itemPrice;
        // when we want to update the leaderboard, do something here
    }
    
    
    //TODO
    function viewLeaderBoard() public returns (string[] memory) {
        
    }

    // Check the balance of the caller 
    // Rets:
    //   - (uint256): balance of the caller's account
    // Specs:
    //   - everyone (including non-registered users) can call this function
    function viewBalance() public view returns (uint256) {
        // for all users
        return balances[msg.sender];
    }

    // Check the role of the caller
    // Rets:
    //   - (uint8): role of the caller
    // Specs:
    //   - check role definitions near the `roles` data structure
    function viewRole() public view returns (uint8) {
        // ============================
        // add your implementation here
        // ============================
        return roles[msg.sender];
    }

    // Register the caller as a host
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only unregistered users can register; otherwise, return false
    //   - a user can only register once; otherwise, return false
    function registerHost() public returns (bool) {
        // ============================
        // add your implementation here
        // ============================
        if(roles[msg.sender] == 0) {
            //only unregistered users
            roles[msg.sender] = 2;
            return true;

        }
        return false;
    }

}
