// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// import "./Leaderboard.sol";

contract RentManager {
    //item struct – the items that we are posting on the market
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
        address buyer;            // the buyer that sends the invoice         
    }

    // Struct representing a Leaderboard entry
    struct lbEntry {
        address user;
        uint256 rank;
        uint256 score;
    }

    // Array of triples representing the leaderboard
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
            Item memory item = Item({
                itemId: itemId,
                itemName: itemName,
                prevSoldPrice: id2item[itemId].prevSoldPrice,
                itemPrice: itemPrice,
                owner: address(msg.sender),
                forsale: forsale
            });
            id2item[item.itemId] = item;
            return true;
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
    function viewItems() public view returns (Item[] memory) {
        Item[] memory forsaleItems = new Item[](items.length);
        uint256 count = 0;
        for(uint256 i = 0; i < items.length; i++) {
            if (items[i].forsale){
                forsaleItems[count] = items[i];
                count++;
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
        
        updateLeaderBoard(item, item.owner);
        //buyer
        balances[invoices[addr2invoice[msg.sender]].buyer] -= item.itemPrice;
        //seller
        balances[invoices[addr2invoice[msg.sender]].item.owner] += item.itemPrice;
        // change the owner of the item
        item.owner = invoices[addr2invoice[msg.sender]].buyer;
        item.prevSoldPrice = item.itemPrice;
        return true;
    }
    
    function updateLeaderBoard(Item memory item, address owner) public returns (bool) {
        // first, we need to check if the current user is already on the leaderboard
        uint256 lbEntryPosition;
        bool found = false;
        for (uint i = 0; i < leaderboard.length; i++){
            if (owner == leaderboard[i].user){
                found = true;
                lbEntryPosition = i;
            }
        }
        // if current user is not in the leaderboard, then create a new leaderboard entry for the user - make a new score and update the ranks
        uint discount;
        if (item.prevSoldPrice > item.itemPrice){
            discount = item.prevSoldPrice - item.itemPrice;
        } else {
            discount = 0;
        }
        
        // if there is no discount made, then we don't update the leaderboard at all
        if (discount == 0){
            return false;
        }
        
        if (!found){
            // create a new leaderboard entry if the user is not found on the leaderboard
            lbEntry memory le = lbEntry({
                user: owner,
                rank: leaderboard.length + 1, // placeholder
                score: discount
            });
            leaderboard.push(le);
        }

        // if the user is in the leaderboard, then update the score of the user and update the ranks
        if (found) {
            leaderboard[lbEntryPosition].score += discount;
        }
        sortLeaderBoard(0, leaderboard.length - 1);
        return true;
    }
    function sortLeaderBoard(uint left, uint right) public  {
        if (left >= right) {
            return;
        }
        uint p = leaderboard[(left + right) / 2].score;
        uint i = left;
        uint j = right;
        while (i < j){
            while (leaderboard[i].score < p){
                i++;
            }
            while (leaderboard[j].score > p){
                j--;
            }
            if (leaderboard[i].score > leaderboard[j].score){
                lbEntry memory temp = leaderboard[i];
                leaderboard[i] = leaderboard[j];
                leaderboard[j] = temp;
                // (leaderboard[i], leaderboard[j]) = (leaderboard[j], leaderboard[i]);
            }
            else {
                i++;
            }
        }
        if (j > left){
            sortLeaderBoard(left, j - 1);
        }
        sortLeaderBoard(j + 1, right);
    }
    


    //Returns the current leaderboard as an array of strings
    function viewLeaderBoard() public view returns (string[] memory) {
        string[] memory s = new string[](leaderboard.length);
        for (uint256 i = 0; i < leaderboard.length; i++) {
            s[i] = string.concat("User: ", toString(leaderboard[i].user), ", Rank: ", uint2str(leaderboard[i].rank), ", Score: ", uint2str(leaderboard[i].score));
        }
        return s;
    }
     
    // below function from GeeksForGeeeks https://www.geeksforgeeks.org/type-conversion-in-solidity/
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
         
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
         
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
         
        return string(str);
    }
    
    //below function from https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
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
