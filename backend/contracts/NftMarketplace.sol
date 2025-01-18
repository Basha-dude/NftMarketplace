// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/* 
*****SWAPPING******
1.staking
2.pricefeed
3.dao
4.can pay with erc-20
5.commission for platform
 ii)royalities for creators
6.bridges or interoperability protocols.
7.Lending/Borrowing:
8.Auctions
9.NFT Bundles:
10. In-Platform Messaging:
Allow buyers and sellers to communicate directly through a secure chat system.
11. Gamification:
Add achievement badges for users based on their activity (e.g., "Top Seller," "Early Supporter").
12.NFT as Membership Tokens:
Enable NFTs to act as access passes for events, platforms, or exclusive content.
*/

import {INFT} from "./Interface/INFT.sol";
import {NFT} from "./NFT.sol";  

/* 
1.re-entrancy gaurd

*/



contract NftMarketplace {

  ////////////////////
  // STATE VARIABLE//
  //////////////////

    uint256 public ItemId;
    address nftContract; 
    uint PRECISION = 1e18;
    uint256 PERCENT = 100;

   
     //////////////////
    // ERRORS       //
    /////////////////

    error NftMarketplace__PriceIsZero(uint price);
    error NftMarketplace__DidNotApproved(address marketplace);
    error NftMarketplace__NotTheOwner(address another);
    error NftMarketplace__RoyalityCreator(uint royality);

   

    /////////////////
    // MAPPING     //
    /////////////////

    //mapping for the id and the MarketItem struct
    mapping (uint256 => MarketItem) idToMarketItem;

    //////////////////
    // STRUCT      //
    /////////////////
     
    /* 
    creating a struct for the marketitem, which is nft in the  marketplace
    */ 
    struct MarketItem {
      uint256 Marketid;
      uint256 NftId;  
    address payable sellerOrOwner;
    address buyer;
    uint256 royalityForCreator;
    uint256 price;
    bool sold;

    }

    MarketItem[] public marketItems;

    constructor(address _NftContract) 
     {
      nftContract = _NftContract;
    }


     ///////////////////
   ////FUNCTIONS     //
  ///////////////////

  /// @notice calculating the fees from the price and roayality
  /// @dev creating the item in marketplace 
  /// @param  tokenId id of the nft
  /// @param _royalityForCreator royality in percentage for the creator
  ///@param _price price  for the nft in marketplace
  /// @return uint256 itemId as the id of nft in marketplace


  // add pricefeed to buy this using the usd 
  function createMarketItem(uint256 tokenId,uint256 _royalityForCreator,uint256 _price) public payable  returns(uint256) {
   address  owner = INFT(nftContract).ownerOf(tokenId);
   uint fee = calculateMarketFee(_price,_royalityForCreator);
   require(msg.value >= fee , "pay the fee");
   if (owner != msg.sender) {
       revert  NftMarketplace__NotTheOwner(msg.sender);

   }
   if (_price <= 0) {
    revert  NftMarketplace__PriceIsZero(_price);

}

if (_royalityForCreator <= 0) {
  revert  NftMarketplace__RoyalityCreator(_royalityForCreator);

}
       ItemId++;
       MarketItem memory  marketItem = MarketItem (
          ItemId,
          tokenId,
          payable (msg.sender),
          address(0),
          _royalityForCreator,
          _price,
          false
        );
      
         marketItems.push(marketItem);
         idToMarketItem[ItemId] = marketItem;


        return ItemId;
  }


 /// @notice taking royality as percent
 /// @dev calculating on basis of price and royality
 /// @param price price of the nft 
 ///@param royality royality of the nft
 /// @return fee to pay 

  function calculateMarketFee(uint price,uint royality) public view returns(uint256)  {
                                //10  *  1e18
       uint256 PriceInEther =  price * PRECISION;
              //  console.log("PriceInEther from contract",PriceInEther);
              //  console.log("(PriceInEther * royality)",(PriceInEther * royality));
              //  console.log("PERCENT from the contract",PERCENT);
              //  console.log("price from the contract",price);
              //  console.log("royality from the contract",royality);
      uint fee = (PriceInEther * royality) / PERCENT;
      return fee;

  }
        
   ///////////////////
   ////VIEW         //
  ///////////////////
  function VerifyTheApproved(uint256 tokenId) public view returns(bool) {
    return INFT(nftContract).getApproved(tokenId) != address(this);
  }
     //////////////////
    // GETTERS      //
    /////////////////

    function getNftContractAddress() public view returns(address) {
      return nftContract;
    }

     function getPRECISION() public view returns(uint) {
      return PRECISION;
     }

    function getmarketItemsLength() public view returns(uint) {
      return marketItems.length;
    }
    function getidToMarketItem(uint tokendId) public view returns(MarketItem memory) {
               return idToMarketItem[tokendId];
    }
}



