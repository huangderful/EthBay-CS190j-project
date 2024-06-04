# EthBay-CS190j-project

## A project by Team ETHsentials
Richard Huang, Jonathan Cheng, Andrew Yu

## Acknowledgments
Yanju Chen, Junrui Liu, Professor Fred Feng

# Documentation

## APIs
Currently we are not using any APIs or external libraries.

## How to set up the environment and initialize the application
All you need to set up the environment is foundry: https://book.getfoundry.sh/getting-started/installation. 

## Components and their Functionalities
These are listed in the same order as they appear in our code.
### Structs
1. Item
    - A struct representing an item that is being sold on the marketplace. Its corresponding fields are:
        - uint256 itemId: An id to uniquely identify the item.
        - string itemName: The name of the item posted.
        - uint256 itemPrice: The price of the item posted.
        - uint256 prevSoldPrice: The price that the current item was previously sold for. If the item has never been sold before, it is initialized to zero.
        - address owner: The address of the owner of the item.
        - bool forsale: A boolean to indicate whether the item is for sale or not.
2. lbEntry
    - A struct representing a user and their corresponding metadata for a leaderboard entry. Its fields contain:
        - address user: The address of the user the entry corresponds to.
        - uint256 rank: The current rank of the user in the leaderboard.
        - uint256 score: The current score of the user in the leaderboard. The user with the highest score is ranked at the top of the leaderboard. Scores are calculated using the price the item was previously sold for minus the price the item was posted for currently.
3. bidder
    - A struct representing a user and their corresponding bid for an item. 
    - When a user attempts to purchase an item, they create a bid for an item – that bid contains the following fields:
        - address user: The address of the user that made this purchase request.
        - uint256 amount: The amount of currency that the user has put up to purchase the item with.
### Objects
1. lbEntry[] public leaderboard
    - A sorted array of lbEntry items. This object represents our leaderboard of sellers. Sellers who have sold with the highest cumulative discounts are at the top of the leaderboard (i.e. the beginning of the array).
2. address private admin
    - The address of the admin user, who sets up the transaction manager and distributes rewards.
3. uint256 private currItemId
    - A field which starts at 0 and is incremented every time a new item is added to items array. Essentially, it represents the index of the last item added so that new items are easy to add.
4. mapping(address => uint8) private roles
    - The mapping of a user to its role. Each user is placed into this map when they register, and given their corresponding role (i.e. all users should have role 2 – user, except for the admin).
5. mapping(address => uint256) private balances
    - The mapping of an address to its balance. More specifically, it is the mapping of a user’s address to their corresponding balance.
6. mapping(uint256 => bidder[]) private bidders;
    - The mapping of itemIds to their bidders. Each item that has been posted on the market for sale will be mapped to an array of bids that have been made on that item.
7. Item[] private items
    - The array of all items currently existing in the marketplace regardless of their “forsale” condition. When a new item is posted it is pushed to this array.
8. mapping(uint256 => Item) private id2item;
    - The mapping of item IDs to their specific item. 

### Functions
1. constructor
    - Initializes the admin to role 1
    - Initializes currItemId to 0 (which represents the start of the items array)
    - Creates a default template for our item struct and pushes it onto the items array
2. addBalance returns bool
    - Params: uint256 amount
    - Adds balance to a user or admin and returns true if successful
3. postItem returns uint256
    - Params: uint256 itemId, string itemName, uint256 itemPrice, bool forsale
    - If itemId = 0 (user intends to post a new item), posts a new item with fields equal to the values of the remainder of the params
    - If itemId != 0 (user intends to modify an existing item) edits the existing item with id = itemId and sets its fields equal to the remainder of the params. An item can be unlisted for sale using this function as well.
4. viewItems returns Item[]
    - Params: none
    - Returns an array of all the Items that are currently for sale, with length equal to the total number of items
5. viewItem returns Item
    - Params: itemId
    - Returns the item associated with the provided item ID
6. purchaseItem returns bool
    - Params: uint256 itemId, uint256 amount
    - Add a bid to the item associated with the item ID you provide as long as you are a registered user, the itemId you provide is valid, the item associated with the item ID is for sale, the amount you provide at least your balance, and the amount you provide is at least the item price.
    - Returns true on success and false if any of the conditions prior are not met.
7. sellItem returns bool
    - Params: uint256 itemId
    - Called by a seller to confirm and enact the sale of an item with id = itemId. '
    - Checks if the item exists, if the caller is the current owner of the item, and if the requisite number of bids (>=3) exists for that item, and returns false if any check fails.
    - Iterates through the bidders[] array for the sold item and gets the highest bidder. Calls updateLeaderBoard with the item and its current owner in case this sale causes a change to the leaderboard. Then, performs the sale to the highest bidder by setting balances and updating the sold item’s fields, and clears the bidders[] array for the item. Finally returns true.
8. updateLeaderBoard returns bool
    - Params: Item item, address owner
    - This private function is used by sellItem to update the leaderboard. 
    - If the leaderboard contains the owner, then we modify the original score with the discount they provided
    - The discount is calculated by subtracting the item’s previous sold price and the current item price (if the item price is larger than the previous sold price the discount is 0)
    - If no discount is made, we return false and don’t update the leaderboard
    - If the leaderboard does not contain the owner, then we create a new leaderboard entry and push it to the leaderboard
    - Finally we sort the leaderboard and return true on success
9. sortLeaderBoard returns null
    - Params: uint left, uint right
    - Using recursive calls to itself, performs a standard sort across the leaderboard based on users’ scores and ranks the leaderboard from highest score to lowest score. Returns null once sort is complete. 
10. viewLeaderBoard returns string[]
    - Params: none
    - Iterates across the leaderboard and returns an array of strings, each containing the user address, rank, and score for each user at a specific rank, in rank order.
11. toString returns string
    - Params: address _addr
    - This function was taken from GeeksForGeeks and returns an address as a human legible string.
12. uint2str returns string 
    - Params: uint _i
    - Function taken from Stack Overflow 
    - Returns a string representing the input unsigned int
13. viewBalance returns uint256
    - Params: none
    - Returns the balance of the sender
14. viewRole returns uint8
    - Params: none
    - Returns the role of the sender
15. registerUser returns bool
    - Params: none
    - Registers any unregistered user as a registered user by assigning them role = 2
    - Upon success it returns true, but if the sender already has a role, it returns false
16. distributeRewards returns bool
    - Params: uint256 reward
    - If caller is the admin check if the reward to be distributed is within admin balance, if not within balance return false or if caller is not admin return false
    - If caller is the admin and the reward is within balance distributes reward to rank 1 user on the leaderboard and returns true

## User Roles
1. There is only one class of registered user, a combined buyer/seller role who can fully participate in the marketplace through posting, buying, and selling items in order to progress on the leaderboard for a chance to obtain rewards. 
2. Unregistered users cannot interact with the project and must register in order to participate in the marketplace.
3. An admin is necessary to start the contract and distribute rewards. There is no way for a user to become admin after the contract has been set up.

## Written with Solidity
