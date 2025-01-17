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




contract NftMarketplace {

  ////////////////////
  // STATE VARIABLE//
  //////////////////

    uint256 public ItemId;
    address nftContract; 

   



     //////////////////
    // ERRORS       //
    /////////////////

    error NftMarketplace__PriceIsZero(uint price);
    error NftMarketplace__DidNotApproved(address marketplace);
    error NftMarketplace__NotTheOwner(address another);

   

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
      uint256 id;
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


    //not complete i think this has some problem
    function ApproveForcreateMarketItem(uint256 tokenId) public  {
      address owner = INFT(nftContract).ownerOf(tokenId);
      if (owner!= msg.sender) {
        revert NftMarketplace__NotTheOwner(msg.sender);
      }

      if (INFT(nftContract).getApproved(tokenId) != address(this)) {
        INFT(nftContract).approve(address(this),tokenId);
      }
    }

}
