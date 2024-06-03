// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// import "./Leaderboard.sol";
import "./ReentrancyGuard.sol";

contract TransactionManager is ReentrancyGuard {
    //item struct – the items that we are posting on the market
    struct Item {
        uint256 itemId;
        string itemName;
        uint256 itemPrice;
        uint256 prevSoldPrice;
        address owner;
        bool forsale;
    }

    // Struct representing a Leaderboard entry
    struct lbEntry {
        address user;
        uint256 rank;
        uint256 score;
    }

    struct bidder {
        address user;
        uint256 amount;
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

    // maps a item id to its bidders
    mapping(uint256 => bidder[]) private bidders;

    // array of all items
    Item[] private items;

    // maps an address to its item
    // the item id can be used as index to access the 'items' array
    mapping(uint256 => Item) private id2item;

    constructor() {
        roles[msg.sender] = 1;
        // create dummy item for default item to connect to
        currItemId = 0;
        Item memory defaultItem = Item({
            itemId: 0,
            itemName: "default",
            itemPrice: 0,
            prevSoldPrice: 0,
            owner: address(0),
            forsale: false
        });
        items.push(defaultItem);
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
    
    //add or edit item
    function postItem(uint256 itemId, string calldata itemName, uint256 itemPrice, bool forsale) nonReentrant public returns (uint256) {
        if(roles[msg.sender] != 2){
            return 0;
        }
        // check if the item exists yet or not
        if (itemId != 0) {
            // check if the owner of the item is the same as the one posting it
            if (msg.sender != id2item[itemId].owner){
                return 0;
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
            return itemId;
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
            return item.itemId; 
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

    // view a specific item that is being sold
    function viewItem(uint256 itemId) public view returns (Item memory) {
        return id2item[itemId];
    }
    
    // place a bid on an item
    function purchaseItem(uint256 itemId, uint256 amount) public returns (bool) {
        if (roles[msg.sender] != 2){
            return false;
        }
        if(itemId > items.length || itemId <= 0) {
            return false;
        }
        Item memory item = id2item[itemId];
        if (!item.forsale){
            return false;
        }
        if(amount > balances[msg.sender]) {
            return false;
        } 
        if(amount < item.itemPrice){
            return false;
        }
        bidder memory bidGuy = bidder({
            user: msg.sender, 
            amount: amount
        });
        
        bidders[itemId].push(bidGuy);
        return true;
    }

    // function called by the owner of an item to confirm the sale of that item – item is sold to the highest bidder in a block
    function sellItem(uint256 itemId) nonReentrant public returns (bool) {
        // check if the item exists
        if (itemId == 0){
            return false;
        }
        // check if the owner of the item is the same person who is attempting to sell it
        if (msg.sender != id2item[itemId].owner){
            return false;
        }

        // check if the item can be sold yet – i.e. the timestamp is valid
        if (bidders[itemId].length < 3) {
            return false;
        }

        uint256 currAmount = 0;
        bidder memory highestBidder;
        for(uint i = 0; i < bidders[itemId].length; i++) {
            if (bidders[itemId][i].amount > currAmount) {
                highestBidder = bidders[itemId][i];
                currAmount = bidders[itemId][i].amount;
            }
        }
        
        Item memory item = id2item[itemId];

        //do all this in end bidding
        updateLeaderBoard(item, item.owner);
        //buyer
        balances[highestBidder.user] -= highestBidder.amount;
        //seller
        balances[msg.sender] += highestBidder.amount;
        // change the owner of the item
        item.owner = highestBidder.user;
        item.prevSoldPrice = highestBidder.amount;
        item.forsale = false;
        id2item[itemId] = item;
        while (bidders[itemId].length > 0) {
            bidders[itemId].pop();
        }
        
        return true;
    }
    
    function updateLeaderBoard(Item memory item, address owner) private returns (bool) {
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
        if (discount == 0) {
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
    
    function sortLeaderBoard(uint left, uint right) private  {
        if (left >= right) {
            return;
        }
        uint p = leaderboard[(left + right) / 2].score;
        uint i = left;
        uint j = right;
        while (i < j){
            while (leaderboard[i].score > p){
                i++;
            }
            while (leaderboard[j].score < p){
                j--;
            }
            if (leaderboard[i].score < leaderboard[j].score){
                lbEntry memory temp = leaderboard[i];
                leaderboard[i] = leaderboard[j];
                leaderboard[j] = temp;
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
            s[i] = string.concat("User: ", toString(leaderboard[i].user), ", Rank: ", uint2str(i + 1), ", Score: ", uint2str(leaderboard[i].score));
        }
        return s;
    }
     
    // below function from GeeksForGeeeks https://www.geeksforgeeks.org/type-conversion-in-solidity/
    function toString(address _addr) public pure returns (string memory) {
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
    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
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
    function registerUser() public returns (bool) {
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
    // the admin distributes the rewards
    function distributeRewards(uint256 reward) public returns (bool) {
        // if the leaderboard is empty, then it is not valid to distribute rewards
        if (leaderboard.length == 0){
            return false;
        }
        if (roles[msg.sender] == 1) {
            if (reward > balances[msg.sender]) {
                return false;
            } else {
                // if the user at the top of the leaderboard no longer exists (i.e. has self destructed), we should return false
                
                balances[msg.sender] -= reward;
                balances[leaderboard[0].user] += reward;
                return true;
            }
        }
        return false;
    }

    receive() external payable {
        // Revert on unexpected Ether transfers
        revert("Direct Ether transfer not allowed");
    }
    fallback() external payable {
        revert("Direct Ether transfer not allowed");
    }

}
