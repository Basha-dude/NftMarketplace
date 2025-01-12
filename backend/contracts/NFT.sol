// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";




contract NFT is ERC721 {
    constructor() ERC721("Undefeated","UDF")
     {
      
    }

}
