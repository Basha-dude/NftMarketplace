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
     
/*  
 */
contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20Mintable; 
    /* FORMULA:-
     
         APR= 10% = 0.1
    secondsInYear = 31,536,000
    Reward Rate was pre-scaled by 1e18 


                    0.1×1e18
    Reward Rate =  -------------- =  ≈3.17×10**9 (stored as ‘3170000000‘)
                     31,536,000

​
   */
    uint private s_rewardRate = 3170000000; // 3.17e9 ≈ 10% APR
     IERC20Mintable  immutable  REWARD_TOKEN;
    address s_marketPlace;

    ////////////////////
    //    EVENTS      //
    /////////////////////
    event Staked(address indexed user, uint amount, uint timestamp);



    ////////////////////
    //    ERRORS      //
    /////////////////////
    error Staking__AmountIsZero();
    error Staking__rewardAmountIsZero();
    error Staking__InvalidMarketplaceAddress();


    
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
constructor(address _rewardToken, address _marketplace) {
       REWARD_TOKEN = IERC20Mintable(_rewardToken);
       s_marketPlace = _marketplace;   
}
    /* 
    ikkada first kontha amount deposit chesthaadhu appudu rewards entha ani calculate cheyyali 
    and we appudey `lastUpdateTime` add chesaam 
    second malli amount deposit chesinappudu malli first nunchi unnnatu untadhi,
    NOTE:here  `stake()` not only for the marketplace it is also for the user,
                                               who are independent to stake from the marketplace
    */


   function stake(address _token,uint amount) public nonReentrant {
        _stake(_token,msg.sender,amount); 
   } 
   /** 
    * @dev mainly used for marketplace and for staking behalf of other user 
   */
    function _stake(address _token,address user,uint amount) public nonReentrant {
        //checks
        if  (amount == 0) {
            revert Staking__AmountIsZero();
        } 
        /* 
        first chesina stake ki rewards add chesaam and last updated time ni set chesaam,
        so second daani ki fresh ga start avthadhi
        */
       UserInfo storage userInfo = userInformation[user]; // Use USER parameter
    
       // 1. Calculate rewards for EXISTING deposit FIRST
       if (userInfo.DepositedAmount > 0) {
           uint pending = calculateRewards(userInfo.DepositedAmount, user);
           userInfo.rewardAmount += pending;
       }
        //effects
         userInformation[user].DepositedAmount += amount;
        userInformation[user].token = _token;
                   /*  
      BUG:- userInformation[msg.sender].lastUpdateTime = block.timestamp;
            uint pendingRewards = _calculateRewards(Amount,user); 
    NOTE:- This would calculate rewards for 0 seconds because you just updated the timestamp!  AND
           This causes new deposits to immediately earn rewards for the entire elapsed time since the last stake, 
                               even though they weren't deposited during that period. 
     */  
           userInformation[user].lastUpdateTime = block.timestamp;

             //interactions
        /* 
       NOTE: speciatlity of safeTransferFrom:
        If the transfer fails or if the token does not behave as expected, it reverts the transaction.

        */
        emit Staked(user,amount,userInformation[user].lastUpdateTime);
        if (msg.sender == s_marketPlace) {
            IERC20Mintable(_token).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            // Normal staking from user
            IERC20Mintable(_token).safeTransferFrom(user, address(this), amount);
        }        //need to emit an event

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

   /// @notice Calculates the reward for the amount
   /// @dev No need to worry about the decimals because the reward token has 18 decimals
   /// @param amount amount to calculate the the rewards
   /// @param user to calculate the amount for the user address
   /// @return rewards for the given amount
   
   function calculateRewards(uint amount, address user) public  view returns (uint) {
    if (userInformation[user].DepositedAmount == 0) return 0;
    if (amount == 0) {
        revert Staking__AmountIsZero();
    }
    uint timeLapsed = block.timestamp - userInformation[user].lastUpdateTime;
    return (amount * s_rewardRate * timeLapsed); 
}

// External function for msg.sender (uses function overloading)
function calculateRewards(uint amount) public  view returns (uint) {
    return calculateRewards(amount, msg.sender);     
}

// External function for any specified user


//  NOTE:-  if i try to distribute there will so many stakers it will give me Dos(Denail of service attack)
    // function distributeRewards() nonReentrant public {}

/**
 */   
 function claimReward() public nonReentrant {
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
        s_rewardRate = newRate;
    }
    
    function emergencyWithdraw() public nonReentrant {
        claimReward();
    }
 
    function setMarketplace(address _marketplace) external {
        if (_marketplace == address(0)) {
            revert Staking__InvalidMarketplaceAddress();
        }
        s_marketPlace = _marketplace;
    }

    //////////////////
    //   GETTERS    //
    //////////////////
    function getRewardRate() external view returns(uint) {
        return s_rewardRate; 
    }

}