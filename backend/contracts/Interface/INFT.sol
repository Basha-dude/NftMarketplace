// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

interface INFT   {
    function mint(string memory tokenURI) external   returns(uint256);   
    function getApproved(uint256 tokenId) external  view  returns(address); 
    function approve(address to,uint256 tokenId) external;    
    function ownerOf(uint256 id) external view returns (address);
   
    
}
