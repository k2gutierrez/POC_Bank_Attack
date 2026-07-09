<div align="center">
  <h1>🏦 PoC Bank Attack (Reentrancy)</h1>
  <p><b>A practical demonstration of smart contract vulnerabilities and secure state management using Foundry.</b></p>
</div>

## 📖 About the Project

The **PoC Bank Attack (Reentrancy)** is a Web3 Smart Contract security project built with **Solidity** and tested using the **Foundry** framework. At its core, the project provides a highly realistic proof of concept of one of the most infamous vulnerabilities in decentralized finance (DeFi): the Reentrancy Attack.

The repository includes a vulnerable banking contract, an attacker contract designed to exploit it, and a securely refactored banking contract. This architecture perfectly illustrates how malicious actors can drain a protocol's funds by recursively calling a withdrawal function before the contract's internal state is updated. 

This project demonstrates a deep understanding of EVM execution contexts, fallback functions, malicious vector analysis, and defensive programming using the **Checks-Effects-Interactions** pattern. It is an ideal showcase for Web3 security researchers, smart contract auditors, and DeFi developers aiming to write bulletproof code.

**Key Technical Highlights:**
* **Solidity `0.8.24`:** Demonstrating that even modern Solidity compilers require careful architectural design to prevent reentrancy.
* **Security Mitigation:** Implementation of state-first balance updates to break recursive execution flows.
* **Foundry Framework:** Complete with high-speed testing, execution simulation, console logging, and state assertions via Arbitrum RPC (or local Anvil environments).

---

## ⚙️ How It Works

The project is divided into three main components:
1.  **`SimpleBank`:** A vulnerable contract where users can deposit and withdraw ETH. The vulnerability lies in transferring ETH to the user *before* zeroing out their balance in the state mapping.
2.  **`Attacker`:** A malicious contract that deposits a small amount of ETH, requests a withdrawal, and uses a `receive()` fallback function to recursively call `withdraw()` on the bank before the bank can update the attacker's balance.
3.  **`FixedBank`:** A secured version of the bank that caches the user's balance, zeroes it out in the mapping (the *effect*), and only then transfers the ETH (the *interaction*).

### Architecture Diagram

![Project Diagram](./images/diagram.png)


[SimpleBank.sol](./src/SimpleBank.sol) - Vulnerable Bank Contract

[FixedBank.sol](./src/FixedBank.sol) - Secured Bank Contract

[Attacker.sol](./src/Attacker.sol) - Malicious Exploit Contract

---

## 💻 Technical Docs

The primary interaction points of the application handle the exploitation of the vulnerable `withdraw` function and the architectural correction in the fixed contract.

### The Vulnerability (`SimpleBank.sol`)
Notice how the external `call` to `msg.sender` happens before `userBalance[msg.sender]` is set to `0`. This leaves the window open for reentrancy.

```solidity
    function withdraw() public {
        require(userBalance[msg.sender] >= 1 ether, "User has not enough balance");
        require(address(this).balance > 0, "Ban is rekt");

        // VULNERABILITY: External interaction before state update
        (bool success, ) = msg.sender.call{value: userBalance[msg.sender]}("");
        require(success, "fail");

        userBalance[msg.sender] = 0;
    }
```

### The Exploit (Attacker.sol)
The attacker initiates the attack, but the real damage is done inside the receive() function. Every time SimpleBank sends ETH, the receive function is triggered, immediately calling withdraw() again while the bank still thinks the attacker has a balance.

```Solidity
    function attack() external payable {
        simpleBank.deposit{value: msg.value}();
        simpleBank.withdraw(); // Initiates the first withdrawal
        
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    // Triggered automatically when receiving ETH from the bank
    receive() external payable {
        if (address(simpleBank).balance >= 1 ether) {
            simpleBank.withdraw(); // Recursive call!
        }
    }
```

### The Fix (FixedBank.sol)
By caching the balance into memory and updating the storage state to 0 before interacting with the external address, the recursive loop is broken. If the attacker tries to re-enter, the require check will fail.

```Solidity
    function withdraw() public {
        require(userBalance[msg.sender] >= 1 ether, "User has not enough balance");
        require(address(this).balance > 0, "Ban is rekt");

        // MITIGATION: Checks-Effects-Interactions pattern
        uint256 balance = userBalance[msg.sender];
        userBalance[msg.sender] = 0; // State is updated first

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "fail");
    }
```

🚀 Execution Example
Here is a step-by-step example of how the test suite simulates the attack on the SimpleBank contract.

Step 1: Setup & Funding
The SimpleBank contract is deployed. A legitimate user (USER1) deposits 50 ETH into the bank to provide it with liquidity. The attacker is funded with 10 ETH.

Step 2: Attacker Initialization
The attacker deploys the Attacker contract, pointing it at the vulnerable SimpleBank address.

Step 3: The Exploit
The attacker calls attack() with 10 ETH. The attacker contract deposits the 10 ETH into SimpleBank and immediately calls withdraw().

Step 4: The Reentrancy Loop
SimpleBank verifies the 10 ETH balance and sends 10 ETH to the attacker contract. The attacker contract's receive() function catches the ETH and, noticing the bank still has funds, instantly calls withdraw() again. Because SimpleBank hasn't reached the line of code that sets the attacker's balance to 0, it passes the checks and sends another 10 ETH.

Step 5: The Aftermath
This loop continues until the bank is entirely drained of USER1's 50 ETH. The test assertions prove that while USER1's internal state still claims they have 50 ETH, the bank's actual ETH balance is 0, and the attacker walks away with 60 ETH total (their initial 10 + the stolen 50).

Step 6: The Fixed Bank Simulation
When this exact same flow is attempted against FixedBank, the transaction safely reverts. The FixedBank updates the balance to 0 before sending the funds, meaning the receive() loop immediately fails the userBalance[msg.sender] >= 1 ether check on the second pass.

⬆️ Installation
Ensure you have Foundry installed on your machine. Install the required project dependencies using the command below:

```Bash
forge install foundry-rs/forge-std
````

🧪 Testing

```bash
    forge test -vvvv)
```

📊 Coverage

```bash
    forge coverage
```