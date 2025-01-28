// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/* 
*****
SWAPPING******
1.staking
3.dao
4.can pay with erc-20(not my own,have to be existed erc-20s)
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


/* 
these imports which not inhereted for is for ABI, to interact with a contract we need ABI and its address */
import {INFT} from "./Interface/INFT.sol";
import {NFT} from "./NFT.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {INFTEvents} from "./Interface/INFTEvents.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/* 
1.re-entrancy gaurd

*/

//completed  0) 
//Now   1) need to do this `4.can pay with erc-20(not my own,have to be existed erc-20s) now
 //need to   2) need  daily should complete one feature 
          
contract NftMarketplace is INFTEvents,ReentrancyGuard { 
    ////////////////////
    // STATE VARIABLE//
    //////////////////

    uint256 public ItemId;
    address nftContract;
    uint PRECISION = 1e18;
    uint256 PERCENT = 100;
    uint commission = 1e14; 

    AggregatorV3Interface ethUsdpriceFeed;
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
    error NftMarketplace__NotTheSellerOrOwner(address another);
    error NftMarketplace__NotExist(uint itemid);
    error NftMarketplace__TokenAddressesAndPriceFeedAddressesAmountsDontMatch(); 
    error NftMarketplace__TokenAddressIsEmptyOrZeroAdress();
    error NftMarketplace__AmountIsZeroForBuyingWithErc();




    /////////////////
    // MAPPING     //
    /////////////////

    //mapping for the id and the MarketItem struct
    mapping(uint256 => MarketItem) idToMarketItem;
    mapping(address  => address ) private TokensPriceFeeds;


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

    constructor(address _NftContract, address _priceFeed,address[] memory tokenAddresses, address[] memory priceFeedAddresses) {
        nftContract = _NftContract;
        ethUsdpriceFeed = AggregatorV3Interface(_priceFeed);
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert NftMarketplace__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        for (uint i = 0; i < tokenAddresses.length; i++) {
            TokensPriceFeeds[tokenAddresses[i]] = priceFeedAddresses[i]; 
        }
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
        (, int256 answer, , , ) = ethUsdpriceFeed.latestRoundData(); //200_000_000_000

        // answer in usd for eth
        /* 
    e.x. 1 ETH = $2000  
         4000/2000 = 2
     */
        console.log("price from the contract in USD", price);//5500
        console.log("royality from the contract in USD", royality);
        console.log("answer from the contract in USD", uint(answer)); //200_000_000_000
        uint256 answerInUsd = uint(answer) * ADDITIONAL_PRECISION; //2_000_000_000_000_000_000_000

        console.log("answerInUsd from the contract in USD", answerInUsd); //2_000_000_000_000_000_000_000
        console.log(
            "uint(answer) * ADDITIONAL_PRECISION in USD ",
            uint(answer) * ADDITIONAL_PRECISION
        ); //2_000_000_000_000_000_000_000

        uint256 priceToEthDecimal = price * PRECISION;
        console.log("price * PRECISION in USD", price * PRECISION); //2_000_000_000_000_000_000
        console.log("priceToEthDecimal in USD", priceToEthDecimal); //2 000 000 000 000 000 000

        // 4_000_000_000_000_000_000_000 /
        // 2_000_000_000_000_000_000_000
        console.log("priceToEthDecimal in USD", priceToEthDecimal);
        console.log("answerInUsd from the contract in USD", answerInUsd);
        //priceToEthDecimal             2_000_000_000_000_000_000
        //answerInUsd from the contract 2_000_000_000_000_000_000_000
        uint256 eth = (priceToEthDecimal  * PRECISION) / answerInUsd; //0 
        console.log("eth IN USD", eth);

        uint fee = (eth * royality ) / PERCENT;
        console.log(
            "eth * royality * PRECISION) IN USD ",
            (eth * royality * PRECISION)
        );

        console.log("fee from the contract IN USD", fee);

        return fee;
    }

    /// @notice Folows checks effects interaction
    /// @dev  though the price is in usd, pays in eth
    /// @param itemId is id of nft in this marketplace

    //need to transfer the royality and add the price can  change by the owner
    function buy(uint itemId) public payable nonReentrant {
        //checks
        MarketItem storage marketItem = idToMarketItem[itemId];   
        address payable originalSeller = marketItem.sellerOrOwner;

        if (marketItem.sold) {
            revert NftMarketplace__AlreadySold(itemId);
        }
        if (VerifyTheApproved(marketItem.NftId)) {
            revert NftMarketplace__DidNotApproved(address(this));
        }
        if (
            marketItem.sellerOrOwner == msg.sender ||
            marketItem.Creator == msg.sender
        ) {
            revert NftMarketplace__CannotBuyHisToken(itemId);
        }
        //here not to the marketplace to the sellerOrOwner
      

        //royality to the creator 
        uint priceToPay;
        uint royalityToPay;
        uint commissionInBuy; 
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
            console.log("priceToPay in  the contract USD",priceToPay); 
            commissionInBuy =  calculateTheCommision(priceToPay);
            console.log(" FROM USD priceToPay + royalityToPay + commissionInBuy",priceToPay + royalityToPay + commissionInBuy);

            require(msg.value >= priceToPay + royalityToPay + commissionInBuy, "Insufficent Usd to buy");   
        } else {
            priceToPay = (marketItem.price * PRECISION );
                        console.log("priceToPay in eth the contract",priceToPay);
                        commissionInBuy = calculateTheCommision(priceToPay);
                        console.log(" FROM ETH priceToPay + royalityToPay + commissionInBuy",priceToPay + royalityToPay + commissionInBuy);
                        require(msg.value >= priceToPay + royalityToPay + commissionInBuy, "Insufficent Eth to buy");
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
    /// @notice only for the tokens which has 18 decimals or 8 decimals
    /// @dev Buying the nft with existing erc
    /// @param itemId is the id of the nft in the marketplace  
    /// @param token is the address of the token to buy the nft in the marketplace    
    /// @param amount is how much tokens     
    function buyTheNftWithErc(uint itemId,address token,uint amount)  public{
         if (token != address(0)) {
            revert NftMarketplace__TokenAddressIsEmptyOrZeroAdress();
         }
         if (amount <= 0) {
            revert NftMarketplace__AmountIsZeroForBuyingWithErc();
         }
         MarketItem storage marketItem = idToMarketItem[itemId];   
         address payable originalSeller = marketItem.sellerOrOwner;
         if (marketItem.sold) {
            revert NftMarketplace__AlreadySold(itemId);
        }
        if (VerifyTheApproved(marketItem.NftId)) {
            revert NftMarketplace__DidNotApproved(address(this));
        }
        if (
            marketItem.sellerOrOwner == msg.sender ||
            marketItem.Creator == msg.sender
        ) {
            revert NftMarketplace__CannotBuyHisToken(itemId);
        }
           uint tokenDecimals = IERC20Metadata(token).decimals(); 
           uint price;
           if (marketItem.isUsd) {
             price = calculateUsdToPayPrice(marketItem.price);
           }
           else{ 
            price = marketItem.price;  
             
           }
        if (tokenDecimals == 18) {
            // Logic for tokens with 18 decimals (most common, e.g., DAI, USDT, etc.)
            // Your logic here
          uint tokenToPay =  calculateTokenToEighteendecimals(price,token);
               bool success =  IERC20Metadata(token).transferFrom(msg.sender,address(this),tokenToPay);
               require(success, "Transfer failed");
        
        } else {
            // Logic for tokens with 8 decimals (e.g., WBTC, BTC)
            // Your logic here
            calculateTokenToEightdecimals(price,token);


            }
    }
     /* this is given correct */ 
    function calculateTokenToEighteendecimals(uint Nftprice,address token) public view returns(uint) {
        address pricefeed =TokensPriceFeeds[token];
        (, int256 answer, , , ) = AggregatorV3Interface(pricefeed).latestRoundData();
        //price 1eth = 2dai
        //eth = 2/1 dai
        console.log("(Nftprice * PRECISION)  from the contract",(Nftprice * PRECISION));
        //4_000_000_000_000_000_000_000_000_000_000_000_000
        console.log("(Nftprice)  from the contract",(Nftprice)); //2_000_000_000_000_000_000


        console.log("answer  from the contract",uint(answer)); //1_000_000_000_000_000
                    //2000 1e18 * 1e18              //6 1e18
     uint amount =  (uint(answer) * Nftprice) /  ( PRECISION * PRECISION);  //2000000000000000000000
     console.log("amount  from the contract",amount);    //1_000_000_000_000_000

      return amount;

        
    }
    function calculateTokenToEightdecimals(uint Nftprice,address token) public {
        
    } 

    function reListInTheMarket(uint _itemId,uint _price,bool _isUsd) public payable {
        if (!checkItExits(_itemId)) {
            revert NftMarketplace__NotExist(_itemId); 
        }
        MarketItem storage marketItem = idToMarketItem[_itemId];   
        address payable originalSeller = marketItem.sellerOrOwner;
        address creator = creatorOfNft(_itemId);

        if (msg.sender != originalSeller) {
             revert NftMarketplace__NotTheSellerOrOwner(msg.sender); 
        }
        if (_price <= 0) {
            revert NftMarketplace__PriceIsZero(_price);
        }
        uint feeTopay;
        if (_isUsd) {
            feeTopay = calculateMarketFeeForUsd(_price, marketItem.royalityForCreator);
            require(msg.value >=feeTopay, "Insuffient Usd for Listing");
        } else{
            feeTopay = calculateMarketFeeForEth(_price, marketItem.royalityForCreator);
            require(msg.value >=feeTopay, "Insuffient Eth for Listing");

        }

        marketItem.price = _price;
        marketItem.isUsd = _isUsd; 
        marketItem.sold = false;

        emit MarketPlace_ReListInTheMarket(
            _itemId,
            marketItem.NftId,
            creator,
            payable(msg.sender),
            marketItem.royalityForCreator,
            _price,
            _isUsd,
            false
        );
        
    }

    function checkItExits(uint _ItemId) public view  returns(bool){
           return  _ItemId > 0 && _ItemId <= ItemId;
    }


    function calculateUsdToPayPrice(
        uint priceInUsd
    ) public view returns (uint) {
        uint priceFromPricefeed = priceFromethUsdpriceFeed();
        uint priceFromPriceFeedInEth = priceFromPricefeed *
            ADDITIONAL_PRECISION;
        uint priceInUsdToEth = priceInUsd * PRECISION;
        uint priceToPay = (priceInUsdToEth * PRECISION) / 
            priceFromPriceFeedInEth;
        return priceToPay;
    }
                                  //price comes as 1e18   
    // function calculateTheCommision(uint price) public view  returns(uint) {
    //     console.log("price from the calculateTheCommision from the contract USD ",price);
    //     console.log("(  price  *  commission ) from the calculateTheCommision from the contract USD ",(  price  *  commission ));
    //     console.log("(PERCENT * PRECISION ) from the calculateTheCommision from the contract USD ",(PERCENT * PRECISION ));

    //       console.log("( price * commission) from the calculateTheCommision from the contract USD ",(  price  *  commission ) / (PERCENT * PRECISION ));
    //       uint commissionToPay =(price * commission) / (PERCENT * PRECISION) * PRECISION / 1e14;
    //       console.log("commissionToPay from the calculateTheCommision from the contract USD ",commissionToPay);

    //      return commissionToPay;  
    // }

    function calculateTheCommision(uint price) public view returns(uint) {
        uint intermediateStep1 = price * commission;
        console.log("intermediateStep1:", intermediateStep1);
        
        uint intermediateStep2 = PERCENT * PRECISION;
        console.log("intermediateStep2:", intermediateStep2);
        
        uint intermediateStep3 = intermediateStep1 / intermediateStep2;
        console.log("intermediateStep3:", intermediateStep3);
        
        uint intermediateStep4 = intermediateStep3 * PRECISION / 1e16;
        console.log("intermediateStep4:", intermediateStep4);
        
        return intermediateStep4;
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

    function getethUsdpriceFeed() public view returns (address) {
        return address(ethUsdpriceFeed);
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

    function priceFromethUsdpriceFeed() public view returns (uint) {
        (, int256 answer, , , ) = ethUsdpriceFeed.latestRoundData();

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
//4 000000000000000000000 000_000_000_000_000
//2 000000000000000000000