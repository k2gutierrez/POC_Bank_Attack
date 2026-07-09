// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract FixedBank {

    // User balance in contract
    mapping(address => uint256) public userBalance;

    /**
     * @dev deposit eth in contract
     */
    function deposit() public payable {
        require(msg.value >= 1 ether, "Minimum deposit is 1 ETH");
        userBalance[msg.sender] += msg.value;
    }

    /**
     * @dev withdraw all the user balance from the contract
     */
    function withdraw() public {
        require(userBalance[msg.sender] >= 1 ether, "User has not enough balance");
        require(address(this).balance > 0, "Ban is rekt");

        uint256 balance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "fail");
    }

    /**
     * @dev Function to know the total balance of the contract (Bank)
     */
    function totalBalance() public view returns(uint) {
        return address(this).balance;
    }
}