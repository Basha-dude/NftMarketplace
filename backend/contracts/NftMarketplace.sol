// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/* 
*****SWAPPING******
1.staking
3.dao
4.can pay with erc-20
5.commission for platform
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

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {INFTEvents} from "./Interface/INFTEvents.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/* 
1.re-entrancy gaurd

*/

//need to 1)write test for buy and  royality
          //2) write commission for the platform
          
contract NftMarketplace is INFTEvents {
    ////////////////////
    // STATE VARIABLE//
    //////////////////

    uint256 public ItemId;
    address nftContract;
    uint PRECISION = 1e18;
    uint256 PERCENT = 100;
    AggregatorV3Interface priceFeed;
    uint ADDITIONAL_PRECISION = 1e10;

    //////////////////
    // ERRORS       //
    /////////////////

    error NftMarketplace__PriceIsZero(uint price);
    error NftMarketplace__DidNotApproved(address marketplace);
    error NftMarketplace__NotTheOwner(address another);
    error NftMarketplace__RoyalityCreator(uint royality);
    error NftMarketplace__AlreadySold(uint tokenId);
    error NftMarketplace__CannotBuyHisToken(uint tokenId);
    error NftMarketplace__BuyTransferFailed();
    error NftMarketplace__RoyalityCreatorIsTooHigh(uint royality);
    error NftMarketplace__BuyCreatorRoyalityTransferFailed();

    /////////////////
    // MAPPING     //
    /////////////////

    //mapping for the id and the MarketItem struct
    mapping(uint256 => MarketItem) idToMarketItem;

    //////////////////
    // STRUCT      //
    /////////////////

    /* 
    creating a struct for the marketitem, which is nft in the  marketplace
    */
    struct MarketItem {
        uint256 Marketid;
        uint256 NftId;
        address payable Creator;
        address payable sellerOrOwner;
        uint256 royalityForCreator;
        uint256 price;
        bool isUsd;
        bool sold;
    }

    constructor(address _NftContract, address _priceFeed) {
        nftContract = _NftContract;
        priceFeed = AggregatorV3Interface(_priceFeed);
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
    function createMarketItem(
        uint256 tokenId,
        uint256 _price,
        uint256 _royalityForCreator,
        bool isUsd
    ) public payable returns (uint256) {
        address creator = INFT(nftContract).ownerOf(tokenId);
        if (_price <= 0) {
            revert NftMarketplace__PriceIsZero(_price);
        }

        if (_royalityForCreator <= 0) {
            revert NftMarketplace__RoyalityCreator(_royalityForCreator);
        }
        if (_royalityForCreator > 25) {
            revert NftMarketplace__RoyalityCreatorIsTooHigh(
                _royalityForCreator
            );
        }
        if (isUsd) {
            console.log("logged ito the usd");
            uint feeForPriceInUSD = calculateMarketFeeForUsd(
                _price,
                _royalityForCreator
            );
            require(
                msg.value >= feeForPriceInUSD,
                "pay the fee for price in usd"
            );
        } else {
            console.log("logged ito the ETH");

            uint feeForPriceInEth = calculateMarketFeeForEth(
                _price,
                _royalityForCreator
            );
            console.log("feeForPriceInEth from the contract", feeForPriceInEth);
            console.log("price from the contract IN ETH", _price);
            console.log(
                "royality from the contract IN ETH",
                _royalityForCreator
            );

            require(
                msg.value >= feeForPriceInEth,
                "pay the fee for price in eth"
            );
        }

        if (creator != msg.sender) {
            revert NftMarketplace__NotTheOwner(msg.sender);
        }

        ItemId++;
        MarketItem memory marketItem = MarketItem(
            ItemId,
            tokenId,
            payable(creator),
            payable(msg.sender),
            _royalityForCreator,
            _price,
            isUsd,
            false
        );

        idToMarketItem[ItemId] = marketItem;

        emit MarketPlace_CreateMarketItem(
            ItemId,
            tokenId,
            creator,
            payable(msg.sender),
            _royalityForCreator,
            _price,
            isUsd,
            false
        );
        return ItemId;
    }

    /// @notice taking royality as percent
    /// @dev calculating on basis of price and royality
    /// @param price price of the nft
    ///@param royality royality of the nft
    /// @return fee to pay

    function calculateMarketFeeForEth(
        uint price,
        uint royality
    ) public view returns (uint256) {
        //10  *  1e18
        uint256 PriceInEther = price * PRECISION;
        //  console.log("PriceInEther from contract",PriceInEther);
        //  console.log("(PriceInEther * royality)",(PriceInEther * royality));
        //  console.log("PERCENT from the contract",PERCENT);
        //  console.log("price from the contract",price);
        //  console.log("royality from the contract",royality);
        uint fee = (PriceInEther * royality) / PERCENT;
        return fee;
    }

    function calculateMarketFeeForUsd(
        uint price,
        uint royality
    ) public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //200_000_000_000

        // answer in usd for eth
        /* 
    e.x. 1 ETH = $2000  
         4000/2000 = 2
     */
        console.log("price from the contract", price);
        console.log("royality from the contract", royality);
        console.log("answer from the contract", uint(answer)); //200_000_000_000
        uint256 answerInUsd = uint(answer) * ADDITIONAL_PRECISION; //2_000_000_000_000_000_000_000

        console.log("answerInUsd from the contract", answerInUsd); //2_000_000_000_000_000_000_000
        console.log(
            "uint(answer) * ADDITIONAL_PRECISION",
            uint(answer) * ADDITIONAL_PRECISION
        ); //2_000_000_000_000_000_000_000

        uint256 priceToEthDecimal = price * PRECISION;
        console.log("price * PRECISION", price * PRECISION); //2_000_000_000_000_000_000
        console.log("priceToEthDecimal", priceToEthDecimal); //2 000 000 000 000 000 000

        // 4_000_000_000_000_000_000_000 /
        // 2_000_000_000_000_000_000_000
        console.log("priceToEthDecimal", priceToEthDecimal);
        console.log("answerInUsd from the contract", answerInUsd);
        //priceToEthDecimal             2_000_000_000_000_000_000
        //answerInUsd from the contract 2_000_000_000_000_000_000_000
        uint256 eth = priceToEthDecimal / answerInUsd; //0
        console.log("eth", eth);

        uint fee = (eth * royality * PRECISION) / PERCENT;
        console.log(
            "eth * royality * PRECISION)",
            (eth * royality * PRECISION)
        );

        console.log("fee from the contract usd", fee);

        return fee;
    }

    /// @notice Folows checks effects interaction
    /// @dev  though the price is in usd, pays in eth
    /// @param itemId is id of nft in this marketplace

    //need to transfer the royality and add the price can  change by the owner
    function buy(uint itemId) public payable {
        //checks
        MarketItem storage marketItem = idToMarketItem[itemId];   
        address payable originalSeller = marketItem.sellerOrOwner;

        if (marketItem.sold) {
            revert NftMarketplace__AlreadySold(itemId);
        }
        if (
            marketItem.sellerOrOwner == msg.sender ||
            marketItem.Creator == msg.sender
        ) {
            revert NftMarketplace__CannotBuyHisToken(itemId);
        }
        //here not to the marketplace to the sellerOrOwner
      

        //royalirty to the creator 
        uint priceToPay;
        uint royalityToPay;
        if (marketItem.isUsd) {
            royalityToPay = calculateMarketFeeForUsd(marketItem.price,marketItem.royalityForCreator);
            console.log("royality usd to from the contract",royalityToPay);
        } else {
            priceToPay = marketItem.price;
            royalityToPay = calculateMarketFeeForEth(marketItem.price,marketItem.royalityForCreator);
            console.log("royality usd to from the contract",royalityToPay);

        }

        if (marketItem.isUsd) {
            priceToPay = calculateUsdToPayPrice(marketItem.price);
            priceToPay = priceToPay;
            require(msg.value >= priceToPay, "Insufficent Usd to buy");   
        } else {
            priceToPay = (marketItem.price * PRECISION );
                        console.log("priceToPay in eth the contract",priceToPay);

            require(msg.value >= priceToPay , "Insufficent Eth to buy");
        }
        address creator = creatorOfNft(itemId);

        //effects
        marketItem.sellerOrOwner = payable(msg.sender);
        marketItem.sold = true;
        emit MarketPlace_Buy(
            itemId,
            marketItem.NftId,
            creator,
            msg.sender,
            marketItem.royalityForCreator,
            marketItem.price,
            marketItem.isUsd,
            true
        );
        //interactions
        //price
        (bool sellerSuccess, ) = originalSeller.call{
            value: priceToPay
        }("");
        if (!sellerSuccess) revert NftMarketplace__BuyTransferFailed();

        //royality
        (bool royalityForCreatorSuccess, ) = marketItem.Creator.call{
            value: royalityToPay
        }("");
        if (!royalityForCreatorSuccess)
            revert NftMarketplace__BuyCreatorRoyalityTransferFailed();

        INFT(nftContract).safeTransferFrom(
           creator,
            msg.sender,
            marketItem.NftId
        );
    }

    function calculateUsdToPayPrice(
        uint priceInUsd
    ) public view returns (uint) {
        uint priceFromPricefeed = priceFromPriceFeed();
        uint priceFromPriceFeedInEth = priceFromPricefeed *
            ADDITIONAL_PRECISION;
        uint priceInUsdToEth = priceInUsd * PRECISION;
        uint priceToPay = (priceInUsdToEth * PRECISION) /
            priceFromPriceFeedInEth;
        return priceToPay;
    }

    ///////////////////
    ////VIEW         //
    ///////////////////
    function VerifyTheApproved(uint256 tokenId) public view returns (bool) {
        return INFT(nftContract).getApproved(tokenId) != address(this);
    }

    //////////////////
    // GETTERS      //
    /////////////////

    function getNftContractAddress() public view returns (address) {
        return nftContract;
    }

    function getPRECISION() public view returns (uint) {
        return PRECISION;
    }

    function getidToMarketItem(
        uint tokendId
    ) public view returns (MarketItem memory) {
        return idToMarketItem[tokendId];
    }

    function getpriceFeed() public view returns (address) {
        return address(priceFeed);
    }

    function getAllMarketItems() public view returns (MarketItem[] memory) {
        MarketItem[] memory items = new MarketItem[](ItemId);
        uint itemid = ItemId;
        console.log("itemid from the contract", itemid);
        //2
        for (uint i = 0; i < itemid; i++) {
            items[i] = idToMarketItem[i + 1];
        }
        return items;
    }

    function priceFromPriceFeed() public view returns (uint) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint(answer);
    }

    function creatorOfNft(uint tokenId) public view returns (address) {
        address creator = idToMarketItem[tokenId].Creator;
        return creator;
    }

    function sellerOrownerOfNft(uint tokenId) public view returns (address) {
        address sellerOrOwner = idToMarketItem[tokenId].sellerOrOwner;
        return sellerOrOwner;
    }
}
