// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import  {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {NftMarketplace} from "./NftMarketplace.sol";

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
    address marketplace;


    ////////////////////
    //    ERRORS      //
    /////////////////////
    error Staking__AmountIsZero();
    error Staking__rewardAmountIsZero();

    
    ////////////////////
    //    STRUCT      //
    /////////////////////
    struct UserInfo{
        address token;
        uint DepositedAmount;
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
    function stake(address _token,address user,uint amount) public nonReentrant {
        //checks
        console.log("msg.sender",msg.sender);
        if  (amount == 0) {
            revert Staking__AmountIsZero();
        }
        /* 
        first chesina stake ki rewards add chesaam and last updated time ni set chesaam,
        so second daani ki fresh ga start avthadhi
        */
        //effects
         userInformation[msg.sender].DepositedAmount += amount;
         uint Amount = userInformation[msg.sender].DepositedAmount;
            userInformation[msg.sender].token = _token;
            userInformation[msg.sender].lastUpdateTime = block.timestamp;
            uint pendingRewards = _calculateRewards(Amount,user);
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
   // Internal function to handle reward calculation logic

   /* 
   need to understand this logic correctly */
function _calculateRewards(uint amount, address user) internal view returns (uint) {
    if (amount == 0) {
        revert Staking__AmountIsZero();
    }
    uint timeLapsed = block.timestamp - userInformation[user].lastUpdateTime;
    return amount * rewardRate * timeLapsed;
}

// External function for msg.sender (uses function overloading)
function calculateRewards(uint amount) external view returns (uint) {
    return _calculateRewards(amount, msg.sender);
}

// External function for any specified user
function calculateRewards(uint amount, address user) external view returns (uint) {
    return _calculateRewards(amount, user);
}

// if i try to distribute there will so many stakers it will give me Dos(Denail of service attack)
    // function distributeRewards() nonReentrant public {}

/** NEED TO CORRECTLY DO THE TRANSFER
 */    function claimReward() public nonReentrant {
    UserInfo storage userinfo = userInformation[msg.sender];
    uint amount = userinfo.rewardAmount;
    //checks
     if (amount == 0) {
        revert Staking__rewardAmountIsZero();    
     }
     //effects
             userinfo.rewardAmount =0;
     //interactions
        REWARD_TOKEN.safeTransferFrom(address(this),msg.sender,amount);
    }

    function emergencyWithdraw() public nonReentrant {}
    
}