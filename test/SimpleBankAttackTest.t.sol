// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {SimpleBank} from "../src/SimpleBank.sol";
import {Attacker} from "../src/Attacker.sol";
import {FixedBank} from "../src/FixedBank.sol";
import {SimpleBankAttackScript} from "../script/SimpleBankAttackScript.s.sol";

contract SimpleBankAttackTest is Test {
    SimpleBank public simpleBank;
    FixedBank public fixedBank;
    Attacker public attackerSimpleBank;
    Attacker public attackerFixedBank;

    // constants
    uint256 constant AMOUNT_DEAL_USER = 100 ether;
    uint256 constant AMOUNT_DEAL_ATTACKER = 10 ether;

    // Users for testing the attack and the test for the fixed bank
    address user1 = makeAddr("USER1"); // LEGIT USER
    address attacker = makeAddr("ATTACKER"); // ATTACKER

    function setUp() public {
        SimpleBankAttackScript deployer = new SimpleBankAttackScript();
        (simpleBank, fixedBank, attackerSimpleBank, attackerFixedBank) = deployer.run();
        vm.deal(user1, AMOUNT_DEAL_USER);
        vm.deal(attacker, AMOUNT_DEAL_ATTACKER);

        vm.prank(user1);
        simpleBank.deposit{value: (AMOUNT_DEAL_USER/2)}(); // for testing, user1 always deploy 50 ether
    }

    ////////////////////    Function tests  ////////////////////

    function testUser1BalanceSimpleBank() public view {

        // We must consider that on setup user1 sent 50 ether

        uint256 contractBalance = simpleBank.totalBalance(); // must be 50 ether
        uint256 userBalance = simpleBank.userBalance(user1); // must be 50 ether

        assert(contractBalance == userBalance);
        assert(contractBalance == (AMOUNT_DEAL_USER/2));
        assert(userBalance == (AMOUNT_DEAL_USER/2));

    }

    function testUser1BalanceFixedBank() public {
        uint256 userBalance = user1.balance; // 50 ether

        vm.prank(user1);
        fixedBank.deposit{value: userBalance}();

        uint256 contractBalance = fixedBank.totalBalance(); // must be 50 ether
        uint256 user1Balance = fixedBank.userBalance(user1); // must be 50 ether

        assert(contractBalance == user1Balance);
        assert(userBalance == user1Balance);
        assert(contractBalance == (AMOUNT_DEAL_USER/2));
        assert(userBalance == (AMOUNT_DEAL_USER/2));
        assert(user1Balance == (AMOUNT_DEAL_USER/2));

    }

    function testDepositAndWithdrawSimpleBank() public {
        uint256 amountToDeposit = 2 ether;
        // We must consider that on setup user1 sent 50 ether
        vm.prank(user1);
        simpleBank.deposit{value: amountToDeposit}();

        uint256 bankBalanceBefore = simpleBank.totalBalance();
        uint256 user1BalanceBefore = simpleBank.userBalance(user1);

        vm.prank(user1);
        simpleBank.withdraw();

        uint256 bankBalanceAfter = simpleBank.totalBalance();
        uint256 user1BalanceInBankAfter = simpleBank.userBalance(user1);

        assert(bankBalanceBefore == (amountToDeposit + (AMOUNT_DEAL_USER/2)));
        assert(user1BalanceBefore == (amountToDeposit + (AMOUNT_DEAL_USER/2)));
        assert(bankBalanceBefore != bankBalanceAfter);
        assert(bankBalanceAfter == 0);
        assert(user1BalanceBefore != user1BalanceInBankAfter);
        assert(user1BalanceInBankAfter == 0);

    }

    function testDepositAndWithdrawFixedBank() public {
        uint256 amountToDeposit = 2 ether;
        // We must consider that on setup user1 sent 50 ether
        vm.prank(user1);
        fixedBank.deposit{value: amountToDeposit}();

        uint256 bankBalanceBefore = fixedBank.totalBalance();
        uint256 user1BalanceBefore = fixedBank.userBalance(user1);

        vm.prank(user1);
        fixedBank.withdraw();

        uint256 bankBalanceAfter = fixedBank.totalBalance();
        uint256 user1BalanceInBankAfter = fixedBank.userBalance(user1);

        assert(bankBalanceBefore == amountToDeposit);
        assert(user1BalanceBefore == amountToDeposit);
        assert(bankBalanceBefore != bankBalanceAfter);
        assert(bankBalanceAfter == 0);
        assert(user1BalanceBefore != user1BalanceInBankAfter);
        assert(user1BalanceInBankAfter == 0);

    }

    ////////////////////    Simple Bank Attack test  ////////////////////

    function testSimpleBankAttackTest() external {
        // there are 50 ether in the Simple Bank from user1 - sent on setup
        // variables before attack
        uint256 user1BankBalance = simpleBank.userBalance(user1); // 50 ether
        uint256 bankBalance = simpleBank.totalBalance();
        uint256 attackerBalance = attacker.balance;

        assert(user1BankBalance == (AMOUNT_DEAL_USER/2));
        assert(bankBalance == user1BankBalance);
        assert(bankBalance == (AMOUNT_DEAL_USER/2));
        assert(attackerBalance == AMOUNT_DEAL_ATTACKER);

        vm.prank(attacker);
        attackerSimpleBank.attack{value: attackerBalance}();

        // variables after attack
        uint256 user1BankBalanceAfterAttack = simpleBank.userBalance(user1); // 0 ether
        uint256 bankBalanceAfterAttack = simpleBank.totalBalance();
        uint256 attackerBankBalance = simpleBank.userBalance(user1);
        uint256 attackerBalanceAfterAttack = attacker.balance;

        console2.log("user 1 bank balance after attack", user1BankBalanceAfterAttack);
        console2.log("bank balance after attack", bankBalanceAfterAttack);
        console2.log("Attacker bank balance", attackerBankBalance);
        console2.log("Attacker balance after attack", attackerBalanceAfterAttack);

        assert(attackerBankBalance == bankBalance); // no update on balance
        assert(user1BankBalanceAfterAttack == bankBalance); // user1 stills see his amount but there is no money in the bank
        assert(attackerBalanceAfterAttack == bankBalance + attackerBalance);

    }

    ////////////////////    Fixed Bank Attack test  ////////////////////

    function testFixedBankAttackTest() external {
        vm.prank(user1);
        fixedBank.deposit{value: (AMOUNT_DEAL_USER / 2)}();
        // variables before attack
        uint256 user1BankBalance = fixedBank.userBalance(user1); // 50 ether
        uint256 bankBalance = fixedBank.totalBalance();
        uint256 attackerBalance = attacker.balance;

        assert(user1BankBalance == (AMOUNT_DEAL_USER/2));
        assert(bankBalance == user1BankBalance);
        assert(bankBalance == (AMOUNT_DEAL_USER/2));
        assert(attackerBalance == AMOUNT_DEAL_ATTACKER);

        vm.expectRevert();
        vm.prank(attacker);
        attackerFixedBank.attack{value: attackerBalance}();

    }

}
