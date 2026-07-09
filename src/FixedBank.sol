// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract FixedBank {

    mapping(address => uint256) public userBalance;

    function deposit() public payable {
        require(msg.value >= 1 ether, "Minimum deposit is 1 ETH");
        userBalance[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(userBalance[msg.sender] >= 1 ether, "User has not enough balance");
        require(address(this).balance > 0, "Ban is rekt");

        uint256 balance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "fail");
    }

    function totalBalance() public view returns(uint) {
        return address(this).balance;
    }
}