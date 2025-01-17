// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";


interface INFTEvents {

    
    event NFT_Mint(
        address owner,
        uint tokenId
    );

}