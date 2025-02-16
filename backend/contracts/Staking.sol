// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import  {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/* 
 *here this is used because IERC20 and ERC20 does not mint function so we use this ```IERC20Mintable```
*/
import {IERC20Mintable} from "./Interface/IERC20Mintable.sol";   

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {NftMarketplace} from "./NftMarketplace.sol";

/**
 * @title StakingContract
 * @notice This contract allows users (or external contracts) to stake an ERC‑20 token.
 *         It tracks deposits and computes rewards over time.
 *
 *         In your case, tokens received from your NFT marketplace (or from users)
 *         can be staked here to accumulate additional rewards.
 * 
 * @dev this  is  ```Annual percentage yield (APY)``` contract
 */

 

 //need to write test for the contract
contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20Mintable; 
    uint public rewardRate = 3170000000; // 3.17e9 ≈ 10% APR
     IERC20Mintable  immutable  REWARD_TOKEN;
    address marketplace;



    
    ////////////////////
    //    EVENTS      //
    /////////////////////
   event Staked();



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
       REWARD_TOKEN = IERC20Mintable(_rewardToken);
}
    /* 
    ikkada first kontha amount deposit chesthaadhu appudu rewards entha ani calculate cheyyali
    second malli amount deposit chesthaadu, appudu malli add chesthaam
    NOTE:here not only for the marketplace it is also for the user,
                                               who are independent to stake from the marketplace
    */


    /* 
      ikkada  STAKE lo logic wrong  ga undi need to correct it, msg.sender antey markeplace avthadhi not user
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
        emit Staked();
       IERC20Mintable(_token).safeTransferFrom(msg.sender,address(this),amount); 
        //need to emit an event

    }
   // Internal function to handle reward calculation logic

   /* 
   need to understand this logic correctly */

   /**                   APR
    * Reward Rate= ------------------ × Scaling Factor (1e18)
                    Seconds in a Year

    *E.X:- 
        Desired APR: 10% = 0.1 (in decimal).
        Seconds in a Year:

     365 days× 24 hours× 3600 seconds=31,536,000 seconds

     Per-Second Rate:
                            0.1                (-9)
                      ---------------   ≈3.17×10       =  (0.00000000317 per second)
                      31,536,000 
           (−9)
    3.17× 10×  1e18=  317,000,000(or 3.17e9)


   */

   /** 
    NOTE: calculation is wrong need to write the correct after testing it 
   */
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

/**
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
        REWARD_TOKEN.mint(msg.sender,amount);       
    }
/* 

need to add owner for this*/
    function setRewardRate(uint newRate) external //onlyOwner
     {
        rewardRate = newRate;
    }
    
    function emergencyWithdraw() public nonReentrant {
        claimReward();
    }
    
}