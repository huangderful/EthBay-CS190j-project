// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Leaderboard {
    //item struct
    struct Item {
        uint256 itemId;
        string itemName;
        uint256 itemPrice;
        uint256 itemDiscount;
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
    
    // Struct representing a Leaderboard entry
    struct lbEntry {
        address user;
        uint256 rank;
        uint256 score;
    }

    // Array of triples
    lbEntry[] public leaderboard;


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


    constructor() {
        roles[msg.sender] = 1;
        // create dummy invoice for default invoice to connect to
        currItemId = 0;
        Item memory defaultItem = Item({
            itemId: 0,
            itemName: "default",
            itemPrice: 0,
            itemDiscount: 0,
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
    
    
    // TODO
    function viewLeaderBoard() public returns (string[] memory) {
        

    }
}
