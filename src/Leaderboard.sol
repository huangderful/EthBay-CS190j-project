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

            uint256 currDiscount;
            if(itemPrice >= id2item[itemId].itemPrice) {
                currDiscount = 0;
            } else {
                currDiscount += id2item[itemId].itemPrice - itemPrice;
            }



            Item memory item = Item({
                itemId: itemId,
                itemName: itemName,
                itemDiscount: currDiscount,
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
                itemDiscount: 0,
                itemPrice: itemPrice,
                owner: address(msg.sender),
                forsale: forsale
            });
            items.push(item);
            id2item[item.itemId] = item;
            return true;
        }
        

        
    }

    //view items that are being sold
    // function viewItems() public returns (Item[] memory) {
    //     Item[] storage forsaleItems;
    //     for(uint256 i = 0; i < items.length; i++) {
    //         if (items[i].forsale){
    //             forsaleItems.push(items[i]);
    //         }
    //     }
    //     return forsaleItems;
    // }

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
    function register() public returns (bool) {
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

    // Send out an invoice to a guest
    // Args:
    //   - toAddr (address): guest address that you want to send the invoice to
    //   - amount (uint256): amount requested
    // Rets:
    //   - (bool): whether the operation is successful
    // Specs:
    //   - only host can send an invoice; otherwise, return false
    //   - an invoice can only be sent to a guest; otherwise, return false
    //   - the host cannot send an invoice if the host has an existing invoice that 
    //     has not been fully paid out yet; in this case, return false
    // function sendInvoice(address toAddr, uint256 amount) public returns (bool) {
    //     // ============================
    //     // add your implementation here
    //     // ============================
    //     if(roles[msg.sender] == 2) {
    //         if(roles[toAddr] == 3) {
    //             if(invoices[addr2invoice[msg.sender]].remainingAmount == 0) {
    //                 addr2invoice[toAddr] = invoices.length;
    //                 addr2invoice[msg.sender] = invoices.length;

    //                 Invoice memory invoice = Invoice({
    //                     amount: amount,
    //                     remainingAmount: amount,
    //                     host: msg.sender,
    //                     guest: toAddr
    //                 });
                    
    //                 invoices.push(invoice);
    //                 return true;
    //             }
                
    //         }
    //     }

    //     return false;
    // }

    // View the latest invoice
    // Rets:
    //   - (uint256, uint256, address, address): a 4-tuple indicating total amount requested,
    //     remaining amount that the guest needs to pay, host that sends the invoice, and guest
    //     that receives the invoice
    // Specs:
    //   - only registered users can view invoice; otherwise return (0, 0, address(0), address(0))
    //   - if (for the guest) no invoice has been received before or (for the host) no invoice has
    //     been sent out before, simply return (0, 0, address(0), address(0))
    // function viewInvoice() public view returns (uint256, uint256, address, address) {
    //     // ============================
    //     // add your implementation here
    //     // ============================
    //     if(roles[msg.sender] > 0) {
    //         //host
    //         if(addr2invoice[msg.sender] == 0) {
    //             return (0, 0, address(0), address(0));
    //         }
    //         return (invoices[invoices.length - 1].amount, invoices[invoices.length - 1].remainingAmount,
    //         invoices[invoices.length - 1].host, invoices[invoices.length - 1].guest);
    //     }
    //     return (0, 0, address(0), address(0));
    // }

    // // Pay the invoice
    // // Args:
    // //   - amount (uint256): the amount that the guest wants to pay
    // // Rets:
    // //   - (bool): whether the operation is successful
    // // Specs:
    // //   - only guest can pay invoice; otherwise return false
    // //   - if the amount to pay is more than the guest's balance, return false

    // //   - if the amount to pay is less than the remaining amout of the invoice,
    // //     pay the amount to the corresponding host and update the remaining amount
    // //     on the invoice

    // //   - if the amount to pay is more than the remaining amount of the invoice,
    // //     pay the remaining amout the the corresponding host and update the invoice
    // //     to "paid out" by setting the remaining amount to 0

    // //   - don't forget to deduce the actually paid amount from the guest's balance
    // function payInvoice(uint256 amount) public returns (bool) {
    //     // ============================
    //     // add your implementation here
    //     // ============================
    //     if(roles[msg.sender] == 3) {
    //         if(amount < balances[msg.sender]) {
    //             uint256 remaining = invoices[addr2invoice[msg.sender]].remainingAmount;

    //             if(amount < remaining) {
    //                 balances[invoices[addr2invoice[msg.sender]].host] += amount;
    //                 balances[msg.sender] -= amount;

    //                 invoices[addr2invoice[msg.sender]].remainingAmount -= amount;
    //                 //should be equal to balances[invoices[addr2invoice[msg.sender]].guest]
    //             }
    //             else {
    //                 balances[invoices[addr2invoice[msg.sender]].host] += remaining;
    //                 balances[msg.sender] -= remaining;

    //                 invoices[addr2invoice[msg.sender]].remainingAmount = 0;


    //             }
    //             return true;

                
    //         }
    //     }
    //     return false;
    // }

}
