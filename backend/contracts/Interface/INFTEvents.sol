// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";


interface INFTEvents {

    
    event NFT_Mint(
        address owner,
        uint tokenId
    );

    event MarketPlace_CreateMarketItem (
        uint256 Marketid,
        uint256 NftId,
        address creator,
      address payable sellerOrOwner,
      uint256 royalityForCreator,
      uint256 price,
      bool isUsd,
      bool sold 
    );

    event MarketPlace_Buy (
        uint256 Marketid,
        uint256 NftId,
        address  creator,
      address  sellerOrOwner,
      uint256 royalityForCreator,
      uint256 price,
      bool isUsd,
      bool sold 
    );
}