// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {INFTEvents} from "./Interface/INFTEvents.sol";   




contract NFT is ERC721URIStorage,Pausable,INFTEvents {

    ////////////////////
    // STATE VARIABLES//
    ///////////////////

    using Counters for Counters.Counter; 
   Counters.Counter private  tokenCount;

    //////////////////
    // ERRORS       //
    /////////////////
    error  NFT__TokenURIIsEmpty();
    constructor() ERC721("Undefeated","UDF")  {}






    //////////////////
    // FUNCTIONS   //
    /////////////////


    /// @dev mints the nft only when it is not paused
    /// @param _tokenURI  minting to the address     
    /// @return the id

   function mint(string memory _tokenURI) external whenNotPaused returns (uint256){
       if (bytes(_tokenURI).length <= 0) {
     revert NFT__TokenURIIsEmpty();
          }  
            tokenCount.increment(); //1      
    _safeMint(msg.sender, tokenCount.current()); 
    _setTokenURI(tokenCount.current(), _tokenURI);
    emit NFT_Mint(msg.sender, tokenCount.current());
     return tokenCount.current();
       }


function getTokenId() public view returns (uint) {
    return tokenCount.current(); 
}


}
