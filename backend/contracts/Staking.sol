// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import  {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";







/**
 * @title StakingContract
 * @notice This contract allows users (or external contracts) to stake an ERC‑20 token.
 *         It tracks deposits and computes rewards over time.
 *
 *         In your case, tokens received from your NFT marketplace (or from users)
 *         can be staked here to accumulate additional rewards.
 */

 // need to write correct formula for calculating rewards
contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint rewardRate = 1e14;
    IERC20  immutable  REWARD_TOKEN;

    ////////////////////
    //    ERRORS      //
    /////////////////////
    error Staking__AmountIsZero();
    
    ////////////////////
    //    STRUCT      //
    /////////////////////
    struct UserInfo{
        address token;
        uint amount;
        uint lastUpdateTime;
        uint rewardAmount;
    }

     ////////////////////
    //    MAPPING      //
    /////////////////////

    mapping (address => UserInfo) userInformation;
       
constructor(address _rewardToken) {
       REWARD_TOKEN = IERC20(_rewardToken);
}
    /* 
    ikkada first kontha amount deposit chesthaadhu appudu rewards entha ani calculate cheyyali
    second malli amount deposit chesthaadu, appudu malli add chesthaam
    NOTE:here not only for the marketplace it is also for the user,
                                               who are independent to stake from the marketplace
    */
    function stake(address _token,uint amount) public nonReentrant {
        //checks
        if  (amount == 0) {
            revert Staking__AmountIsZero();
        }
        /* 
        first chesina stake ki rewards add chesaam and last updated time ni set chesaam,
        so second daani ki fresh ga start avthadhi
        */
        //effects
         userInformation[msg.sender].amount += amount;
         uint Amount = userInformation[msg.sender].amount;
            userInformation[msg.sender].token = _token;
            userInformation[msg.sender].lastUpdateTime = block.timestamp;
            uint pendingRewards = calculateRewards(Amount,msg.sender); 
            userInformation[msg.sender].rewardAmount += pendingRewards;      
            userInformation[msg.sender].lastUpdateTime = block.timestamp;


        //interactions
        /* 
        speciatlity of safeTransferFrom:
        If the transfer fails or if the token does not behave as expected, it reverts the transaction.

        */
        IERC20(_token).safeTransferFrom(msg.sender,address(this),amount); 
        //need to emit an event


    }
    function calculateRewards(uint amount,address user) public view returns(uint) {
        if (amount == 0) {
            revert Staking__AmountIsZero();
        }
        uint timeLapsed = block.timestamp - userInformation[msg.sender].lastUpdateTime;
            return  amount * rewardRate * timeLapsed; 
       
    }
 
    function distributeRewards() public {}

    function claimReward() public nonReentrant {
        UserInfo storage userinfo = userInformation[msg.sender];
        
        
    }
    function withdraw() public nonReentrant {}
}