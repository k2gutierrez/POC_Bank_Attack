// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {SimpleBank} from "../src/SimpleBank.sol";
import {Attacker} from "../src/Attacker.sol";
import {FixedBank} from "../src/FixedBank.sol";

contract SimpleBankAttackScript is Script {
    SimpleBank public simpleBank;
    FixedBank public fixedBank;
    Attacker public attackerSimpleBank;
    Attacker public attackerFixedBank;

    // function setUp() public {}

    function run() public returns(SimpleBank, FixedBank, Attacker, Attacker) {
        vm.startBroadcast();

        simpleBank = new SimpleBank();
        fixedBank = new FixedBank();
        attackerSimpleBank = new Attacker(address(simpleBank));
        attackerFixedBank = new Attacker(address(fixedBank));

        vm.stopBroadcast();

        return (simpleBank, fixedBank, attackerSimpleBank, attackerFixedBank);
    }
}
