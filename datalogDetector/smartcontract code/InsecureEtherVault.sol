// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Dependencies.sol";

contract InsecureEtherVault is ReentrancyGuard {
    mapping (address => uint256) private userBalances;

    function deposit() external payable {
        userBalances[msg.sender] += msg.value;
    }

    function transfer(address _to, uint256 _amount) external {
        if (userBalances[msg.sender] >= _amount) {
           userBalances[_to] += _amount;
           userBalances[msg.sender] -= _amount;
        }
    }

    function withdrawAll() external noReentrant {  // Apply the noReentrant modifier
        uint256 balance = getUserBalance(msg.sender);
        require(balance > 0, "Insufficient balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        userBalances[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address _user) public view returns (uint256) {
        return userBalances[_user];
    }
}