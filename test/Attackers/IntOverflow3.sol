// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract IntOverflowAttacker3 {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public {
        tmgr.registerUser();
        tmgr.addBalance(1);
        tmgr.postItem(0, "Impossible", type(uint256).max + 1, true);
    }       

}
