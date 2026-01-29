// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VulnerableRewardPool
 * @notice This contract demonstrates cross-function reentrancy vulnerability
 * 
 * VULNERABILITY PATTERN:
 * - claimRewards() reads user's reward balance and totalClaimed
 * - claimRewards() makes external call to user
 * - User re-enters via donateRewards() function
 * - donateRewards() modifies totalClaimed, affecting the reward calculation
 * - After external call returns, claimRewards() uses stale totalClaimed value
 * 
 * ATTACK SCENARIO:
 * 1. Attacker deposits funds and accumulates rewards
 * 2. Attacker calls claimRewards()
 * 3. claimRewards() reads: rewards = 100, totalClaimed = 50
 * 4. claimRewards() calculates: claimable = 100 - 50 = 50
 * 5. claimRewards() sends 50 tokens to attacker (external call)
 * 6. Attacker's receive() calls donateRewards(30)
 * 7. donateRewards() increases totalClaimed by 30 (now 80)
 * 8. claimRewards() resumes and sets userRewards[attacker] = 50
 * 9. But totalClaimed is now 80, not 50!
 * 10. Attacker can claim again with incorrect state
 */
contract VulnerableRewardPool {
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public userDeposits;
    uint256 public totalClaimed;
    uint256 public totalRewards;
    
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardDonated(address indexed donor, uint256 amount);
    event Deposited(address indexed user, uint256 amount);
    
    /**
     * @notice Deposit funds to earn rewards
     */
    function deposit() external payable {
        require(msg.value > 0, "Must deposit something");
        userDeposits[msg.sender] += msg.value;
        userRewards[msg.sender] += msg.value / 10; // 10% reward
        totalRewards += msg.value / 10;
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @notice Claim accumulated rewards
     * @dev VULNERABLE: Reads totalClaimed, makes external call, then updates state
     */
    function claimRewards() external {
        uint256 rewards = userRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");
        
        // Read current totalClaimed (VULNERABLE POINT 1)
        uint256 currentTotalClaimed = totalClaimed;
        
        // Calculate claimable amount based on total claimed
        uint256 claimable = rewards;
        if (currentTotalClaimed < totalRewards) {
            // Adjust claimable based on what's already been claimed
            claimable = rewards - (currentTotalClaimed * rewards / totalRewards);
        }
        
        require(claimable > 0, "Nothing to claim");
        
        // External call - VULNERABLE POINT 2 (reentrancy entry point)
        (bool success, ) = msg.sender.call{value: claimable}("");
        require(success, "Transfer failed");
        
        emit RewardClaimed(msg.sender, claimable);
        
        // Update state AFTER external call (VULNERABLE POINT 3)
        userRewards[msg.sender] = rewards - claimable;
        totalClaimed += claimable;
    }
    
    /**
     * @notice Donate rewards back to the pool
     * @dev This function can be re-entered during claimRewards() external call
     *      It modifies totalClaimed, affecting the reward calculation
     */
    function donateRewards(uint256 amount) external payable {
        require(msg.value == amount, "Amount mismatch");
        require(amount > 0, "Must donate something");
        
        // Modify totalClaimed - this affects ongoing claimRewards() execution
        totalClaimed += amount;
        totalRewards += amount;
        
        emit RewardDonated(msg.sender, amount);
    }
    
    /**
     * @notice Get user's claimable rewards
     */
    function getClaimableRewards(address user) external view returns (uint256) {
        uint256 rewards = userRewards[user];
        if (totalClaimed >= totalRewards) {
            return 0;
        }
        return rewards - (totalClaimed * rewards / totalRewards);
    }
    
    /**
     * @notice Emergency withdraw (no rewards)
     */
    function emergencyWithdraw() external {
        uint256 deposit = userDeposits[msg.sender];
        require(deposit > 0, "No deposit to withdraw");
        
        userDeposits[msg.sender] = 0;
        userRewards[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: deposit}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @notice Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

