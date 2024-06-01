// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {TransactionManager} from "../src/TransactionManager.sol";

contract TransactionManagerTest is Test {
    TransactionManager public tmgr;

    // ===================== //
    // ==== local roles ==== //
    // ===================== //

    address public admin = address(0x01);
    address public buyer1 = address(0x02);
    address public seller1 = address(0x03);
    
    address public buyer2 = address(0x04);
    address public seller2 = address(0x05);

    address public buyer3 = address(0x06);

    uint256 public init_buyer1_balance = 75 ether;
    uint256 public init_seller1_balance = 25 ether;
    uint256 public init_reward = 1 ether;

    function setUp() public {
        vm.startPrank(admin);
        tmgr = new TransactionManager();
        tmgr.addBalance(init_reward);
        vm.stopPrank();
    }

    function setup_accounts() public {
        vm.startPrank(buyer1);
        tmgr.registerUser();
        vm.stopPrank();

        vm.startPrank(seller1);
        tmgr.registerUser();
        vm.stopPrank();

        vm.startPrank(seller2);
        tmgr.registerUser();
        vm.stopPrank();
    }

    function setup_accounts_with_balances() public {
        vm.startPrank(buyer1);
        tmgr.registerUser();
        tmgr.addBalance(init_buyer1_balance);
        vm.stopPrank();

        vm.startPrank(buyer2);
        tmgr.registerUser();
        tmgr.addBalance(init_buyer1_balance);
        vm.stopPrank();

        vm.startPrank(buyer3);
        tmgr.registerUser();
        tmgr.addBalance(init_buyer1_balance);
        vm.stopPrank();

        vm.startPrank(seller1);
        tmgr.registerUser();
        tmgr.addBalance(init_seller1_balance);
        vm.stopPrank();
    
        vm.startPrank(seller2);
        tmgr.registerUser();
        tmgr.addBalance(init_seller1_balance);
        vm.stopPrank();
    }

    // ========================== //
    // ==== local test cases ==== //
    // ========================== //

    // Feature: User Registration
    function test_user_registration() public {
        vm.startPrank(buyer1);
        assertEq(tmgr.registerUser(), true);
        assertEq(tmgr.viewRole(), 2);
        vm.stopPrank();
    }

    // Feature: registered users can view their balance
    function test_user_balance() public {
        setup_accounts();
        vm.startPrank(buyer1);
        assertEq(tmgr.viewBalance(), 0);
        assertEq(tmgr.addBalance(100), true);
        assertEq(tmgr.viewBalance(), 100);
        vm.stopPrank();
    }
    
    // Feature: A registered user can post an item for sale
    function test_user_post_item() public{
        setup_accounts();
        vm.startPrank(seller1);
        //if itemid is 0 it will generate a new one
        // post 2 new items, and check if the item is posted properly (i.e. they get an incremented item id)
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);
        assertEq(tmgr.postItem(0, "Potato", 1 ether, true), 2);

        // these lines check each item, and
        uint256 rottenId = tmgr.postItem(0, "Rotten Tomato", 1 ether, false);
        assertEq(rottenId, 3); 
        //see if they contain the correct metadata
        assertEq(tmgr.viewItem(rottenId).forsale, false);
        assertEq(tmgr.viewItem(rottenId).itemPrice, 1 ether);

        vm.stopPrank();
    }

    // Feature: A registered user can edit an item they have previously posted for sale
    function test_user_edit_item() public {
        setup_accounts();
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);
        assertEq(tmgr.postItem(0, "Potato", 1 ether, true), 2);

        uint256 rottenId = tmgr.postItem(0, "Rotten Tomato", 1 ether, false);
        assertEq(rottenId, 3);
        
        //these lines change the item and see if the id remains the same while updating 
        rottenId = tmgr.postItem(rottenId, "Good Tomato", 2 ether, true);
        assertEq(rottenId, 3);

        assertEq(tmgr.viewItem(rottenId).itemName, "Good Tomato");
        assertEq(tmgr.viewItem(rottenId).forsale, true);
        assertEq(tmgr.viewItem(rottenId).itemPrice, 2 ether);

        vm.stopPrank();
    }

    // Feature: A registered user can view all items on sale and their prices
    function test_user_view_items() public {
        setup_accounts();
        // 2 sellers post their items (same as above)
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);
        assertEq(tmgr.postItem(0, "Potato", 2 ether, true), 2);
        vm.stopPrank();
        
        vm.startPrank(seller2);
        assertEq(tmgr.postItem(0, "Banana", 3 ether, true), 3);
        assertEq(tmgr.postItem(0, "Orange", 4 ether, true), 4);
        assertEq(tmgr.postItem(0, "Alcohol", 5 ether, false), 5);
        vm.stopPrank();

        // assert buyer able to view all items listed for sale and their values
        vm.startPrank(buyer1);
        assertEq(tmgr.viewItems()[0].itemName, "Tomato");
        assertEq(tmgr.viewItems()[0].itemPrice, 1 ether);
        assertEq(tmgr.viewItems()[0].prevSoldPrice, 0);
        assertEq(tmgr.viewItems()[0].owner, seller1);
        assertEq(tmgr.viewItems()[0].forsale, true);
        
        assertEq(tmgr.viewItems()[1].itemName, "Potato");
        assertEq(tmgr.viewItems()[1].itemPrice, 2 ether);
        assertEq(tmgr.viewItems()[1].prevSoldPrice, 0);
        assertEq(tmgr.viewItems()[1].owner, seller1);
        assertEq(tmgr.viewItems()[1].forsale, true);

        assertEq(tmgr.viewItems()[2].itemName, "Banana");
        assertEq(tmgr.viewItems()[2].itemPrice, 3 ether);
        assertEq(tmgr.viewItems()[2].prevSoldPrice, 0);
        assertEq(tmgr.viewItems()[2].owner, seller2);
        assertEq(tmgr.viewItems()[2].forsale, true);
        
        assertEq(tmgr.viewItems()[3].itemName, "Orange");  
        assertEq(tmgr.viewItems()[3].itemPrice, 4 ether);
        assertEq(tmgr.viewItems()[3].prevSoldPrice, 0);
        assertEq(tmgr.viewItems()[3].owner, seller2);
        assertEq(tmgr.viewItems()[3].forsale, true);

        // the last item posted should appear a, a default item as it is not for sale and its values should be hidden from viewitems
        assertNotEq(tmgr.viewItems()[4].itemName, "Alcohol");  
        assertNotEq(tmgr.viewItems()[4].itemPrice, 5 ether);
        assertNotEq(tmgr.viewItems()[4].prevSoldPrice, 1);
        assertNotEq(tmgr.viewItems()[4].owner, seller2);
        assertNotEq(tmgr.viewItems()[4].forsale, true);
        
        vm.stopPrank();
    }
    
    // Feature: A registered user can purchase an item
    function test_purchase_item() public {
        setup_accounts_with_balances();
        // the seller first posts an itme
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 2 ether, true), 1);
        vm.stopPrank();

        vm.startPrank(buyer1);
        // buys with not enough payment should return false
        // buys on invalid items should return false
        // buys with more payment than existing balance should return false
        assertEq(tmgr.purchaseItem(1, 1 ether), false);
        assertEq(tmgr.purchaseItem(2, 2 ether), false);
        assertEq(tmgr.purchaseItem(1, 76 ether), false);

        // this should be a valid buy
        assertEq(tmgr.purchaseItem(1, 2 ether), true);
        vm.stopPrank();
    }

    // Feature: Several registered users can attempt to purchase an item – the user that bid the most for it in the same block receives the item

    function test_mult_purchase_item() public {
        setup_accounts_with_balances();
        // the seller first posts an itme
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 2 ether, true), 1);
        vm.stopPrank();

        // 3 different buyers place 3 different bids on the item tomato
        vm.startPrank(buyer1);
        assertEq(tmgr.purchaseItem(1, 2 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer2);
        assertEq(tmgr.purchaseItem(1, 3 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer3);
        assertEq(tmgr.purchaseItem(1, 4 ether), true);
        vm.stopPrank();

        // after the seller confirms the sale, the item owner should be the buyer who bid the most
        // the seller's balance should be updated
        vm.startPrank(seller1);
        assertEq(tmgr.sellItem(1), true);
        assertEq(tmgr.viewBalance(), 29 ether);
        vm.stopPrank();

        // check that the buyer's balance updated as well
        // check that the correct buyer owns the item
        vm.startPrank(buyer3);
        assertNotEq(tmgr.viewItem(1).owner, seller1);
        assertNotEq(tmgr.viewItem(1).owner, buyer1);
        assertNotEq(tmgr.viewItem(1).owner, buyer2);
        assertEq(tmgr.viewItem(1).owner, buyer3);
        assertEq(tmgr.viewBalance(), 71 ether);
        vm.stopPrank();
    }

    // Feature: A registered user can post an item for sale after they buy it
    function test_post_item_after_sale() public {
        // make a sale (reuse the previous test to make a sale first)
        test_mult_purchase_item();

        // test if the user can post the item after 
        // test if all the metadata of the item is correct
        vm.startPrank(buyer3);
        assertEq(tmgr.viewItem(1).forsale, false);
        assertEq(tmgr.postItem(1, "Tomato", 3 ether, true), 1);
        assertEq(tmgr.viewItem(1).forsale, true);
        assertEq(tmgr.viewItem(1).itemPrice, 3 ether);
        assertEq(tmgr.viewItem(1).itemName, "Tomato");
        vm.stopPrank();

    }

    // Feature: Checks the integrity of leaderboard conditions: 
    // Items with no previous sale history cannot put user onto the leaderboard
    // invalid sales are not posted, 
    function test_leaderboard_integrity() public {
        // make a sale – this should sell the item "tomato" for 4 ether
        test_mult_purchase_item();
        
        // make a second sale - this should sell the item "tomato" for 2 ether (a discount)
        vm.startPrank(buyer3);
        assertEq(tmgr.viewLeaderBoard().length, 0); // the leaderboard should still be empty as no discounts have been made
        assertEq(tmgr.postItem(1, "Tomato", 2 ether, true), 1);
        vm.stopPrank();

        // 3 potential buyers put a bid on the item – the item should be sold to the bidder with the highest bid
        vm.startPrank(seller1);
        assertEq(tmgr.purchaseItem(1, 2 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer1);
        assertEq(tmgr.purchaseItem(1, 2 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer2);
        assertEq(tmgr.purchaseItem(1, 3 ether), true);
        vm.stopPrank();

        // buyer3 confirms the sale of their resold item for a discount
        vm.startPrank(buyer3);
        // check if the transaction has gone through correctly
        assertEq(tmgr.sellItem(1), true);
        assertNotEq(tmgr.viewItem(1).owner, seller1);
        assertNotEq(tmgr.viewItem(1).owner, buyer1);
        assertNotEq(tmgr.viewItem(1).owner, buyer3);
        assertEq(tmgr.viewItem(1).owner, buyer2);
        assertEq(tmgr.viewBalance(), 74 ether);

        // check if the leaderboard has updated correctly, with discount 2 because discount uses listed price, not sold price
        assertEq(tmgr.viewLeaderBoard().length, 1);
        assertEq(tmgr.viewLeaderBoard()[0], string(abi.encodePacked(
            "User: ", 
            tmgr.toString(buyer3), 
            ", Rank: 1, Score: ", 
            tmgr.uint2str(2 ether)
        )));

        vm.stopPrank();
    }

    // Feature: seller who resells item for a higher price cannot be listed on the leaderboard for that sale / won't have their score updated
    function test_resell_undiscounted_item() public {
        test_leaderboard_integrity();
        // make a third sale - this should sell the item "tomato" for 10 ether (not a discount meaning his score would be 0 if it is sold)
        vm.startPrank(buyer2);
        assertEq(tmgr.viewLeaderBoard().length, 1); // the leaderboard should only have the previous test case's entry
        assertEq(tmgr.postItem(1, "Tomato", 10 ether, true), 1);
        vm.stopPrank();

        // 3 potential buyers put a bid on the item – the item should be sold to the bidder with the highest bid
        vm.startPrank(seller1);
        assertEq(tmgr.purchaseItem(1, 10 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer1);
        assertEq(tmgr.purchaseItem(1, 11 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer3);
        assertEq(tmgr.purchaseItem(1, 12 ether), true);
        vm.stopPrank();

        // buyer3 confirms the sale of their resold item for a discount
        vm.startPrank(buyer2);
        // check if the transaction has gone through correctly
        assertEq(tmgr.sellItem(1), true);
        assertNotEq(tmgr.viewItem(1).owner, seller1);
        assertNotEq(tmgr.viewItem(1).owner, buyer1);
        assertNotEq(tmgr.viewItem(1).owner, buyer2);
        assertEq(tmgr.viewItem(1).owner, buyer3);
        assertEq(tmgr.viewBalance(), 84 ether); // buyer2 = 75 - 3 + 12

        // check if leaderboard only has user from first sale, not the reseller
        assertEq(tmgr.viewLeaderBoard().length, 1);
        
        assertEq(tmgr.viewLeaderBoard()[0], string(abi.encodePacked(
            "User: ", 
            tmgr.toString(buyer3), 
            ", Rank: 1, Score: ", 
            tmgr.uint2str(2 ether)
        )));

        vm.stopPrank();
        
    }
    // Feature: A registered user can view the leaderboard, and the leaderboard updates individual scores correctly
    // When a user sells an item at a discount again, their score on the leaderboard should update
    function test_view_populated_leaderboard() public {

        test_resell_undiscounted_item();
        // make a third sale - this should sell the item "tomato" for 10 ether (not a discount meaning his score would be 0 if it is sold)
        vm.startPrank(buyer3);
        assertEq(tmgr.viewLeaderBoard().length, 1); // the leaderboard should only have the previous test case's entry
        assertEq(tmgr.postItem(1, "Tomato", 7 ether, true), 1);
        vm.stopPrank();

        // 3 potential buyers put a bid on the item – the item should be sold to the bidder with the highest bid
        vm.startPrank(seller1);
        assertEq(tmgr.purchaseItem(1, 7 ether), true);
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        assertEq(tmgr.purchaseItem(1, 8 ether), true);
        vm.stopPrank();
        
        vm.startPrank(buyer2);
        assertEq(tmgr.purchaseItem(1, 9 ether), true);
        vm.stopPrank();
                

        // buyer3 confirms the sale of their resold item for a discount
        vm.startPrank(buyer3);
        // check if the transaction has gone through correctly
        assertEq(tmgr.sellItem(1), true);
        assertNotEq(tmgr.viewItem(1).owner, seller1);
        assertNotEq(tmgr.viewItem(1).owner, buyer1);
        assertNotEq(tmgr.viewItem(1).owner, buyer3);
        assertEq(tmgr.viewItem(1).owner, buyer2);
        assertEq(tmgr.viewBalance(), 71 ether); //75 => 74 => 62 => 71

        // check if the leaderboard has updated correctly
        assertEq(tmgr.viewLeaderBoard().length, 1);
        assertEq(tmgr.viewLeaderBoard()[0], string(abi.encodePacked(
            "User: ", 
            tmgr.toString(buyer3), 
            ", Rank: 1, Score: ", 
            tmgr.uint2str(7 ether) // the original 2 + (12 - 7) = 7
        )));

        vm.stopPrank();
    }

    // Feature: The leaderboard updates rankings after a sale containing a discount
    function test_leaderboard_rankings() public {
        // first, we post 2 items for sale
        setup_accounts_with_balances();
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 10 ether, true), 1);
        assertEq(tmgr.postItem(0, "Potato", 20 ether, true), 2);
        vm.stopPrank();

        // the 3 buyers place different valid bids for the 2 items
        vm.startPrank(buyer1);
        assertEq(tmgr.purchaseItem(1, 15 ether), true);
        assertEq(tmgr.purchaseItem(2, 20 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer2);
        assertEq(tmgr.purchaseItem(1, 10 ether), true);
        assertEq(tmgr.purchaseItem(2, 25 ether), true);
        vm.stopPrank();

        vm.startPrank(buyer3);
        assertEq(tmgr.purchaseItem(1, 10 ether), true);
        assertEq(tmgr.purchaseItem(2, 20 ether), true);
        vm.stopPrank();
        
        // buyer1 gets the tomato, buyer2 gets the potato
        vm.startPrank(seller1);
        // check if the transactions for tomato have gone through correctly
        assertEq(tmgr.sellItem(1), true);
        assertEq(tmgr.viewItem(1).owner, buyer1);
        assertEq(tmgr.viewBalance(), 40 ether); // after selling the tomato, the seller's balance should be 25 + 15 = 40

        // check if the transactions for potato have gone through correctly
        assertEq(tmgr.sellItem(2), true);
        assertEq(tmgr.viewItem(2).owner, buyer2);
        assertEq(tmgr.viewBalance(), 65 ether); // after selling the potato, the seller's balance should be 40 + 25 = 65

        // leaderboard hasn't yet been setup
        assertEq(tmgr.viewLeaderBoard().length, 0);
        vm.stopPrank();

        // check if the balance of buyer1 is correct
        vm.startPrank(buyer1);
        assertEq(tmgr.viewBalance(), 60 ether); // balance of the buyer should be 75 - 15 = 60 
        vm.stopPrank();
        
        // check if the balance of buyer2 is correct
        vm.startPrank(buyer2);
        assertEq(tmgr.viewBalance(), 50 ether); // balance of buyer2 should be 75 - 25 = 50
        vm.stopPrank();
        
        //Have each buyer resell their respective item
        vm.startPrank(buyer1);
        assertEq(tmgr.postItem(1, "Tomato", 5 ether, true), 1); //so buyer1 score = 15 - 5 = 10 if it gets sold      
        vm.stopPrank();

        vm.startPrank(buyer2);
        assertEq(tmgr.postItem(2, "Potato", 5 ether, true), 2); //so buyer1 score = 25 - 5 = 20 if it gets sold
        vm.stopPrank();

        // we sell both of the items to buyer3
        vm.startPrank(buyer3);
        assertEq(tmgr.purchaseItem(1, 5 ether), true);
        assertEq(tmgr.purchaseItem(1, 5 ether), true);
        assertEq(tmgr.purchaseItem(1, 5 ether), true);
        
        assertEq(tmgr.purchaseItem(2, 5 ether), true);
        assertEq(tmgr.purchaseItem(2, 5 ether), true);
        assertEq(tmgr.purchaseItem(2, 5 ether), true);
        vm.stopPrank();
        
        // have each buyer confirm their sales
        vm.startPrank(buyer1);
        assertEq(tmgr.sellItem(1), true);
        assertEq(tmgr.viewItem(1).owner, buyer3);
        assertEq(tmgr.viewBalance(), 65 ether); // buyer1 = 60 + 5 = 65
        vm.stopPrank();

        //confirm buyer
        vm.startPrank(buyer2);
        assertEq(tmgr.sellItem(2), true);
        assertEq(tmgr.viewItem(2).owner, buyer3);
        assertEq(tmgr.viewBalance(), 55 ether); // buyer2 should have a balance of: 50 + 5 = 55
        vm.stopPrank();
        
        vm.startPrank(buyer3);
        // check if the transaction has gone through correctly

        assertEq(tmgr.viewItem(1).owner, buyer3);
        assertEq(tmgr.viewItem(2).owner, buyer3);
        assertEq(tmgr.viewBalance(), 65 ether); // 75 - 5 - 5 

        // check if the leaderboard has updated correctly
        assertEq(tmgr.viewLeaderBoard().length, 2);
        assertEq(tmgr.viewLeaderBoard()[0], string(abi.encodePacked(
            "User: ", 
            tmgr.toString(buyer2), 
            ", Rank: 1, Score: ", 
            tmgr.uint2str(20 ether) // original sell price is 25 eth, it was posted for 5 eth
        )));

        assertEq(tmgr.viewLeaderBoard()[1], string(abi.encodePacked(
            "User: ", 
            tmgr.toString(buyer1), 
            ", Rank: 2, Score: ", 
            tmgr.uint2str(10 ether) // original sell price is 15 eth, it was posted for 5 eth
        )));

        vm.stopPrank();

    }
    //test if we can distribute the reward properly
    function test_reward_distribution() public {
        // distribute the reward as the admin to the highest ranked user in the leaderboard
        test_leaderboard_rankings();
        vm.startPrank(admin);
        assertEq(tmgr.distributeRewards(init_reward), true);
        assertEq(tmgr.viewBalance(), 0 ether);
        vm.stopPrank();

        // buyer2 is rank 1, so should be the recipient
        vm.startPrank(buyer2);
        assertEq(tmgr.viewBalance(), 56 ether);
        vm.stopPrank();
        
        //buyer1 doesn't receive reward so buyer1's balance doesn't change
        vm.startPrank(buyer1);
        assertEq(tmgr.viewBalance(), 65 ether);
        vm.stopPrank();
    }
    
    // potential penetration test cases:

}