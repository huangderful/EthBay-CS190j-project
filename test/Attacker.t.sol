// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {TransactionManager} from "../src/TransactionManager.sol";

//attacker imports:
import {AddBalanceSelfDestructAttacker} from "./Attackers/AddBalanceSelfDestruct.sol";
import {PurchaseSelfDestructAttacker} from "./Attackers/PurchaseSelfDestruct.sol";
import {PostSelfDestructAttacker} from "./Attackers/PostSelfDestruct.sol";
import {LeaderboardSelfDestructAttacker} from "./Attackers/LeaderboardSelfDestruct.sol";

import {IntOverflowAttacker1} from "./Attackers/IntOverflow1.sol";
import {IntOverflowAttacker2} from "./Attackers/IntOverflow2.sol";
import {IntOverflowAttacker3} from "./Attackers/IntOverflow3.sol";

import {FrontRunningAttacker} from "./Attackers/FrontRunning.sol";
import {BuyPhishingAttacker} from "./Attackers/BuyPhishing.sol";
import {SellPhishingAttacker} from "./Attackers/SellPhishing.sol";

import {ReEntrancyAttacker} from "./Attackers/ReEntrancy.sol";


contract AttackerTest is Test {
    TransactionManager public tmgr;
    // IntOverflowAttacker1 ioattacker;

    // ===================== //
    // ==== local roles ==== //
    // ===================== //

    // these are roles of potential users
    // buyers and sellers are labaled based on their initial transasction – posting an item or buying an item
    // however, a buyer can sell an item, and a seller can buy an item
    address public admin = address(0x01);
    address public buyer1 = address(0x02);
    address public seller1 = address(0x03);
    
    address public buyer2 = address(0x04);
    address public seller2 = address(0x05);

    address public buyer3 = address(0x06);

    // initializes the balances of the users
    // the buyers are initialized with a balance of 75 ether
    // the sellers are initialiezed with a balance of 25 ether
    // the reward that is distributed to the top 
    uint256 public init_buyer1_balance = 75 ether;
    uint256 public init_seller1_balance = 25 ether;
    uint256 public init_reward = 1 ether;

    // sets up a transaction manager marketplace – the admin initializes the transactionManager and the reward is given to the admin
    function setUp() public {
        vm.startPrank(admin);
        tmgr = new TransactionManager();
        tmgr.addBalance(init_reward);
        vm.stopPrank();
    }

    // sets up and registers the local users we defined above
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

    // sets up and registers the users we defined above
    // additionally, initializes the user balances
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

    // Feature: A registered user can purchase an item
    // Note: This is not a penetration test, we are just reusing this code to test expected behavior after a penetration test
    // Don't count this toward our penetration test total
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

    // TODO: remove self destructed users from the leaderboard
    // Selfdestruct test
    // the attacker is using selfdestruct to destroy the entire marketplace
    // if the attack is successful, then the contract can no longer be interacted with and no one can make a new transaction
    function test_add_balance_selfdestruct() public {
        // we will set up the transaction manager, register a user, then activate the attack
        setup_accounts_with_balances();
        AddBalanceSelfDestructAttacker sdattacker = new AddBalanceSelfDestructAttacker(tmgr);

        vm.startPrank(buyer2);
        tmgr.addBalance(2 ether);
        vm.stopPrank();
        
        sdattacker.attack();        
        // If we implemented our code correctly, it should not matter that the attacker self destructed, we can still purchase an item
        // the following lines should pass, and this test should pass as well
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

    // Purchases an item then self destruct should still allow for the sale of an item
    // The attacker attempts to buy an item, then self destruct
    // If this attack is successful, this self destruct will cause the transaction manager contract to ccrash
    // If this attack is not successful, the contract will continue to work, despite the self destrcuted user owning this item
    function test_purchase_selfdestruct() public {
        // we will set up the transaction manager, register a user, then activate the attack
        setup_accounts_with_balances();
        PurchaseSelfDestructAttacker sdattacker = new PurchaseSelfDestructAttacker(tmgr);
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);
        vm.stopPrank();

        vm.startPrank(buyer1);
        tmgr.addBalance(6 ether);
        assertEq(tmgr.purchaseItem(1, 2 ether), true);
        assertEq(tmgr.purchaseItem(1, 2 ether), true);
        vm.stopPrank();
        //The attack will submit a bid which outweighs all the other bids and then selfdestructs
        //in an attempt to break our contract. But, unfortunately for the attacker, this doesn't work
        
        sdattacker.attack();
        vm.startPrank(seller1);
        assertEq(tmgr.sellItem(1), true);
        vm.stopPrank();
    }
    
    // selfdestruct 3
    // posting an item then self destructing should still allow for others to post their items
    function test_post_selfdestruct() public {
        setup_accounts_with_balances();
        PostSelfDestructAttacker sdattacker = new PostSelfDestructAttacker(tmgr);
        sdattacker.attack();
        
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 2);
        vm.stopPrank();
    }
    

    // selfdestruct 4
    function test_leaderboard_selfdestruct() public {
        setup_accounts_with_balances();
        LeaderboardSelfDestructAttacker sdattacker = new LeaderboardSelfDestructAttacker(tmgr);

        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "attackedItem", 50 ether, true), 1);
        vm.stopPrank();
        //purchases the 50 ether item
        sdattacker.buy();

        
        vm.startPrank(seller1);
        assertEq(tmgr.sellItem(1), true);
        vm.stopPrank();
        //posts the newly bought item for 5 ether
        sdattacker.post();

        vm.startPrank(buyer1);
        tmgr.addBalance(50 ether);
        assertEq(tmgr.purchaseItem(1, 5 ether), true);
        assertEq(tmgr.purchaseItem(1, 5 ether), true);
        assertEq(tmgr.purchaseItem(1, 5 ether), true);
        vm.stopPrank();
        
        sdattacker.sell();
        sdattacker.attack();

        // we can still distribute rewards even if the attacker self-destructs
        // the attack "fails" because in order to get first place on the leaderboard the attacker must honestly
        // spend money, and by selfdestruct it removes the only way to earn money from the leaderboard placement
        // the attacker attempts to take down the contract by self destruting at the top of the leaderboard
        // if successful, there will be some kind of error/unexpected behavior in the distirbute reward function that takes down the transaction manager contract
        vm.startPrank(admin);
        assertEq(tmgr.distributeRewards(init_reward), true);
        vm.stopPrank();
    }
    
    // IntOverflow 1: attempts to overflow seller's balance by purchasing an item
    // the attacker attempts to destroy the marketplace again by adding an overflowing balance to its own account
    // if the attack is successful then the seller loses all its money
    // intoverflow fails because solidity is version 0.8
    function test_sellerbalanceoverflow() public {
        setup_accounts();
        IntOverflowAttacker1 ioattacker = new IntOverflowAttacker1(tmgr);

        vm.startPrank(seller1);
        tmgr.addBalance(type(uint256).max);
        assertEq(tmgr.postItem(0, "Tomato", 1, true), 1);
        vm.stopPrank();

        ioattacker.attack();
        
        vm.startPrank(seller1);
        // This line will trigger a panic and cause our test to fail which is expected because
        // we should not continue executing with an overflow. This is expected.
        // Expecting: [FAIL. Reason: panic: arithmetic underflow or overflow (0x11)]
        tmgr.sellItem(1);
    }

    function test_bidamountoverflow() public {
        setup_accounts_with_balances();
        IntOverflowAttacker2 ioattacker2 = new IntOverflowAttacker2(tmgr);

        vm.startPrank(seller1);
        tmgr.addBalance(1 ether);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);
        vm.stopPrank();

        ioattacker2.attack();
    
        vm.startPrank(seller1);
        // This line will trigger a panic and cause our test to fail which is expected because
        // we should not continue executing with an overflow. This is expected.
        // Expecting: [FAIL. Reason: panic: arithmetic underflow or overflow (0x11)]
        assertEq(tmgr.sellItem(1), true);
        vm.stopPrank();
    }

    // int overflow test 3: attempts to overflow item price by posting it at a high amount
    // if the attack is successful then the seller creates a free item
    // intoverflow fails because solidity is version 0.8
    function test_itempriceoverflow() public {
        setup_accounts_with_balances();
        IntOverflowAttacker3 ioattacker3 = new IntOverflowAttacker3(tmgr);
        
        // This line will trigger a panic and cause our test to fail which is expected because
        // we should not continue executing with an overflow. This is expected.
        // Expecting: [FAIL. Reason: panic: arithmetic underflow or overflow (0x11)]
        ioattacker3.attack();
    }

    // Frontrunning – a bidder tries to get their bid put in the block first so the item is sold to them,  even though a different bidder may have placed a higher bid bid in the same block.
    // To attempt this, the attacker might set a high gas price on their bid so it is mined before a different user's bid that paid more.
    // If this attack is successful, the owner of the item should be the attacker.
    // If this attack is not successful, the owner of the item should be the user who bid the most in the same block.
    function test_front_running() public {
        setup_accounts_with_balances();
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);
        vm.stopPrank();

        vm.startPrank(buyer1);
        uint256 frontRunnedAmount = 2 ether;
        tmgr.purchaseItem(1, frontRunnedAmount);
        tmgr.purchaseItem(1, frontRunnedAmount);
        vm.stopPrank();

        FrontRunningAttacker frontRunningAttacker = new FrontRunningAttacker(tmgr, frontRunnedAmount, 1);
        frontRunningAttacker.attack();
        
        vm.startPrank(seller1);
        assertEq(tmgr.sellItem(1), true);
        assertEq(tmgr.viewItem(1).owner, buyer1);
        vm.stopPrank();

    }
    
    // Re-Entrancy - an attacker call the contract to sell an item, then before that finishes execution, they call post item to post the item
    // if this attack is successful, the attacker will be able to receive the money from the sale and maintain ownership of that item
    // if the attack is not successful, the ownership of the item will be transfered normally
    function test_re_entrancy() public {
        setup_accounts_with_balances();
        // currently wrong – I want seller1 to be the attacker
        ReEntrancyAttacker reentrancyattacker = new ReEntrancyAttacker(tmgr);
        reentrancyattacker.post();
        
        vm.startPrank(buyer1);
        tmgr.purchaseItem(1, 1 ether);
        tmgr.purchaseItem(1, 1 ether);
        tmgr.purchaseItem(1, 1 ether);
        vm.stopPrank();
       
        reentrancyattacker.attack();
        //HERE
        assertEq(reentrancyattacker.viewAttackerBalance(), 1 ether);

        vm.startPrank(buyer1);
        assertEq(tmgr.viewItem(1).owner, buyer1);
        assertEq(tmgr.viewBalance(), 74 ether);
        vm.stopPrank();
    }


    // Phishing 1 - an attacker attempts to sell an item that they do not own
    // If this attack is successful, the attacker will be able to sell an item posted by another user, and receive the currency from that sale
    // If this attack is not successful, the item will be sold as intended, and the money from the highest bidder is sent to the person who owned the item at the time of the sale
    function test_sell_phishing() public {
        setup_accounts_with_balances();
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);
        vm.stopPrank();

        vm.startPrank(buyer1);
        tmgr.addBalance(6 ether);
        tmgr.purchaseItem(1, 2 ether);
        tmgr.purchaseItem(1, 2 ether);
        tmgr.purchaseItem(1, 2 ether);
        vm.stopPrank();

        vm.startPrank(seller1);
        SellPhishingAttacker phishingAttacker = new SellPhishingAttacker(tmgr);
        phishingAttacker.attack();

        // Assert that after the attack the item still belongs to the user who posted it
        assertEq(tmgr.viewItem(1).owner, seller1);
        vm.stopPrank();
    }

    // Phishing 2 - an attacker attempts to post an item that they do not own
    // If this attack is successful the attacker will be able to edit an existing item to a price of their choosing
    // If this attack is not successful, the item will remain unmodified    
    function test_post_phishing() public {
        setup_accounts_with_balances();
        vm.startPrank(seller1);
        assertEq(tmgr.postItem(0, "Tomato", 1 ether, true), 1);

        BuyPhishingAttacker phishingAttacker = new BuyPhishingAttacker(tmgr);
        phishingAttacker.attack();

        // Assert that after the attack the item still has its original fields
        assertEq(tmgr.viewItem(1).owner, seller1);
        assertEq(tmgr.viewItem(1).itemName, "Tomato");
        vm.stopPrank();
    }
}   