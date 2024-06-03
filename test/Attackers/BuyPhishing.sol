// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract BuyPhishingAttacker {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public payable {
        tmgr.registerUser();
        tmgr.postItem(1, "ATTACKED", 99 ether, true);

    }
}
