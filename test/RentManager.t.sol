// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {RentManager} from "../src/RentManager.sol";

contract RentManagerTest is Test {
    RentManager public rmgr;

    // ===================== //
    // ==== local roles ==== //
    // ===================== //

    address public admin = address(0x01);
    address public host = address(0x02);
    address public guest = address(0x03);
    address public passenger = address(0x04);

    uint256 public init_host_balance = 25;
    uint256 public init_guest_balance = 75;

    function setUp() public {
        vm.startPrank(admin);
        rmgr = new RentManager();
        vm.stopPrank();
    }

    function setup_accounts() public {
        vm.startPrank(host);
        rmgr.registerHost();
        vm.stopPrank();

        vm.startPrank(guest);
        rmgr.registerGuest();
        vm.stopPrank();
    }

    function setup_accounts_with_balances() public {
        vm.startPrank(host);
        rmgr.registerHost();
        rmgr.addBalance(init_host_balance);
        vm.stopPrank();

        vm.startPrank(guest);
        rmgr.registerGuest();
        rmgr.addBalance(init_guest_balance);
        vm.stopPrank();
    }

    // ========================== //
    // ==== local test cases ==== //
    // ========================== //

    // register as a host
    function test_local_host_register() public {
        vm.startPrank(host);
        assertEq(rmgr.registerHost(), true);
        assertEq(rmgr.viewRole(), 2);
        vm.stopPrank();
    }

    // // regular guest registration
    function test_local_guest_register() public {
        vm.startPrank(guest);
        assertEq(rmgr.registerGuest(), true);
        assertEq(rmgr.viewRole(), 3);
        vm.stopPrank();
    }

    // // view and add balance of host
    function test_local_host_balance() public {
        setup_accounts();
        vm.startPrank(host);
        assertEq(rmgr.viewBalance(), 0);
        assertEq(rmgr.addBalance(78), true);
        assertEq(rmgr.viewBalance(), 78);
        vm.stopPrank();
    }

    // // default guest invoice
    function test_local_guest_invoice() public {
        setup_accounts();
        vm.startPrank(guest);
        (uint256 a, uint256 b, address c, address d) = rmgr.viewInvoice();
        assertEq(a, 0);
        assertEq(b, 0);
        assertEq(c, address(0));
        assertEq(d, address(0));
        vm.stopPrank();
    }

    // // regular invoice adding
    function test_local_host_invoice() public {
        setup_accounts();
        vm.startPrank(host);
        assertEq(rmgr.sendInvoice(guest, 10), true);
        (uint256 a, uint256 b, address c, address d) = rmgr.viewInvoice();
        assertEq(a, 10);
        assertEq(b, 10);
        assertEq(c, host);
        assertEq(d, guest);
        vm.stopPrank();
    }

    // // pay invoice partially
    function test_local_transaction0() public {
        setup_accounts_with_balances();
        
        vm.startPrank(host);
        assertEq(rmgr.sendInvoice(guest, 70), true);
        vm.stopPrank();

        vm.startPrank(guest);
        assertEq(rmgr.payInvoice(58), true);
        (uint256 a, uint256 b, address c, address d) = rmgr.viewInvoice();
        assertEq(a, 70);
        assertEq(b, 12);
        assertEq(c, host);
        assertEq(d, guest);
        vm.stopPrank();

        // check balance
        vm.startPrank(host);
        assertEq(rmgr.viewBalance(), init_host_balance + 58);
        vm.stopPrank();
        vm.startPrank(guest);
        assertEq(rmgr.viewBalance(), init_guest_balance - 58);
        vm.stopPrank();
    }

    // // pay invoice in full
    function test_local_transaction1() public {
        setup_accounts_with_balances();
        
        vm.startPrank(host);
        assertEq(rmgr.sendInvoice(guest, 70), true);
        vm.stopPrank();

        vm.startPrank(guest);
        assertEq(rmgr.payInvoice(70), true);
        (uint256 a, uint256 b, address c, address d) = rmgr.viewInvoice();
        assertEq(a, 70);
        assertEq(b, 0);
        assertEq(c, host);
        assertEq(d, guest);
        vm.stopPrank();

        // check balance
        vm.startPrank(host);
        assertEq(rmgr.viewBalance(), init_host_balance + 70);
        vm.stopPrank();
        vm.startPrank(guest);
        assertEq(rmgr.viewBalance(), init_guest_balance - 70);
        vm.stopPrank();
    }

}