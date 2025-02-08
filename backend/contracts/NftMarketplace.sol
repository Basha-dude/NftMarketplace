/* 
*****
SWAPPING Or Exchange******
1.staking
4.from the erc20 we need stake them in the staking platform
6.bridges or interoperability protocols.
7.Lending/Borrowing:
8.Auctions
10. In-Platform Messaging:
Allow buyers and sellers to communicate directly through a secure chat system.

*/

/* 
these imports which not inhereted for is for ABI, to interact with a contract we need ABI and its address */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import {INFT} from "./Interface/INFT.sol";
import {NFT} from "./NFT.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {INFTEvents} from "./Interface/INFTEvents.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// for to transfer nft  to the contract
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

//need to   2) need  daily should complete one feature

//completed  0)royality and tested  the commission and tested
//Now   1) written and tested for buyWithErc and need to test with small values

contract NftMarketplace is INFTEvents, ReentrancyGuard, ERC721Holder {
    ////////////////////
    // STATE VARIABLE//
    //////////////////

    uint256 public ItemId;
    address nftContract;
    uint256 PRECISION = 1e18;
    uint256 PERCENT = 100;
    uint256 public commissionBasisPoints = 200; // 2% = 200/10000

    //1e14 wei is 0.0001% of 1 ether.
    uint256 commissionForNftMarketplace = 1e14;
    uint256 commissionForBuyWithErc = 1e4;

    uint256 EIGHT_DECIMAL = 1e8;
    AggregatorV3Interface ethUsdpriceFeed;
    uint256 ADDITIONAL_PRECISION = 1e10;

    //////////////////
    // ERRORS       //
    /////////////////

    error NftMarketplace__PriceIsZero(uint256 price);
    error NftMarketplace__DidNotApproved(address marketplace);
    error NftMarketplace__NotTheOwner(address another);
    error NftMarketplace__RoyalityCreator(uint256 royality);
    error NftMarketplace__AlreadySold(uint256 tokenId);
    error NftMarketplace__CannotBuyHisToken(uint256 tokenId);
    error NftMarketplace__BuyTransferFailed();
    error NftMarketplace__RoyalityCreatorIsTooHigh(uint256 royality);
    error NftMarketplace__BuyCreatorRoyalityTransferFailed();
    error NftMarketplace__NotTheSellerOrOwner(address another);
    error NftMarketplace__NotExist(uint256 itemid);
    error NftMarketplace__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error NftMarketplace__TokenAddressIsEmptyOrZeroAdress();
    error NftMarketplace__AmountIsZeroForBuyingWithErc();
    error NftMarketplace__InvalidNftContract();
    error NftMarketplace__InvalidPriceFeed();
    error NftMarketplace__EmptyTokenAddresses();
    error NftMarketplace__UnsupportedToken();
    error NftMarketplace__TokenNotSupported(address token);
    error NftMarketplace__ZeroPriceFeed();
    error NftMarketplace__ZeroRoyality();
    error NftMarketplace__ZeroTokensForCalulatingRoyality();

    /////////////////
    // MAPPING     //
    /////////////////

    //mapping for the id and the MarketItem struct
    mapping(uint256 => MarketItem) idToMarketItem;
    mapping(address => address) private TokensPriceFeeds;

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

    constructor(
        address _NftContract,
        address _priceFeed,
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses
    ) {
        if (_NftContract == address(0)) revert NftMarketplace__InvalidNftContract();
        if (_priceFeed == address(0)) revert NftMarketplace__InvalidPriceFeed();
        if (tokenAddresses.length == 0) revert NftMarketplace__EmptyTokenAddresses();
        nftContract = _NftContract;
        ethUsdpriceFeed = AggregatorV3Interface(_priceFeed);
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert NftMarketplace__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
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
    function createMarketItem(uint256 tokenId, uint256 _price, uint256 _royalityForCreator, bool isUsd)
        public
        payable
        returns (uint256)
    {
        console.log("from createMarketItem");
        //checks
        address creator = INFT(nftContract).ownerOf(tokenId);
        if (_price <= 0) {
            revert NftMarketplace__PriceIsZero(_price);
        }

        if (_royalityForCreator <= 0) {
            revert NftMarketplace__RoyalityCreator(_royalityForCreator);
        }
        if (_royalityForCreator > 10) {
            revert NftMarketplace__RoyalityCreatorIsTooHigh(_royalityForCreator);
        }
        uint256 price;
        if (isUsd) {
            price = _price;
            console.log(" from createMarketItem -> logged ito the usd");
            uint256 feeForPriceInUSD = calculateMarketFeeForUsd(price, _royalityForCreator);
            require(msg.value >= feeForPriceInUSD, "pay the fee for price in usd");
        } else {
            price = _price;
            console.log("price from createitesm in eth", price);
            console.log("_______price from createitesm in eth", _price);

            console.log("logged ito the ETH");

            uint256 feeForPriceInEth = calculateMarketFeeForEth(price, _royalityForCreator);
            console.log("feeForPriceInEth from the contract", feeForPriceInEth);
            console.log("price from the contract IN ETH", price);
            console.log("royality from the contract IN ETH", _royalityForCreator);

            require(msg.value >= feeForPriceInEth, "pay the fee for price in eth");
        }

        if (creator != msg.sender) {
            revert NftMarketplace__NotTheOwner(msg.sender);
        }

        //effects

        ItemId++;
        MarketItem memory marketItem =
            MarketItem(ItemId, tokenId, payable(creator), payable(msg.sender), _royalityForCreator, price, isUsd, false);
        ///interactions
        idToMarketItem[ItemId] = marketItem;
        INFT(nftContract).safeTransferFrom((msg.sender), address(this), tokenId);

        emit MarketPlace_CreateMarketItem(
            ItemId, tokenId, creator, payable(msg.sender), _royalityForCreator, _price, isUsd, false
        );
        return ItemId;
    }

    /// @notice taking royality as percent
    /// @dev calculating on basis of price and royality
    /// @param price price of the nft (in wei)
    ///@param royality royality of the nft (in percentage)
    /// @return fee to pay
    //200_000_000
    //in wei           in percentage
    function calculateMarketFeeForEth(uint256 price, uint256 royality) public view returns (uint256) {
        //10  *  1e18
        console.log("from calculateMarketFeeForEth");

        uint256 PriceInEther = price;
        console.log("calculateMarketFeeForEth PriceInEther from contract", PriceInEther);
        console.log("(PriceInEther * royality)", (PriceInEther * royality));
        //  console.log("PERCENT from the contract",PERCENT);
        //  console.log("price from the contract",price);
        console.log("royality from the contract in eth", royality);
        /* took here precision for not truncate the value */
        uint256 fee = (PriceInEther * PRECISION * royality) / PERCENT;
        console.log("fee from the contract in eth", fee);

        return fee;
    }

    /* this(calculateMarketFeeForUsd) is correct also correct for normal and low values */

    //                                          normal like 4000,  2 in percentage
    function calculateMarketFeeForUsd(uint256 price, uint256 royality) public view returns (uint256) {
        (, int256 answer,,,) = ethUsdpriceFeed.latestRoundData(); //200_000_000_000

        // answer in usd for eth
        /* 
    e.x. 1 ETH = $2000  
         4000/2000 = 2
     */
        console.log("from calculateMarketFeeForUsd -> "); //5500

        // console.log("calculateMarketFeeForUsd -> price from the contract in USD", price); //5500
        // console.log("royality from the contract in USD", royality);
        // console.log("answer from the contract in USD", uint256(answer)); //200_000_000_000
        uint256 answerInUsd = uint256(answer) * ADDITIONAL_PRECISION; //2_000_000_000_000_000_000_000

        // console.log("answerInUsd from the contract in USD", answerInUsd); //2_000_000_000_000_000_000_000
        // console.log("uint(answer) * ADDITIONAL_PRECISION in USD ", uint256(answer) * ADDITIONAL_PRECISION); //2_000_000_000_000_000_000_000

        uint256 priceToEthDecimal = price * PRECISION;
        // console.log("price * PRECISION in USD", price * PRECISION); //2_000_000_000_000_000_000
        // console.log("priceToEthDecimal in USD", priceToEthDecimal); //2 000 000 000 000 000 000

        // 4_000_000_000_000_000_000_000 /
        // 2_000_000_000_000_000_000_000
        // console.log("priceToEthDecimal in USD", priceToEthDecimal);
        // console.log("answerInUsd from the contract in USD", answerInUsd);
        //priceToEthDecimal             2_000_000_000_000_000_000
        //answerInUsd from the contract 2_000_000_000_000_000_000_000

        /* 
        here using `PRECISION` because not to truncate the value , means 2.75 -> 2 
        
        */
        uint256 eth = (priceToEthDecimal * PRECISION) / answerInUsd; //0
        console.log("eth IN USD", eth);
        console.log("for price", price);

        uint256 fee = (eth * royality) / PERCENT;
        console.log("eth * royality * PRECISION) IN USD ", (eth * royality * PRECISION));

        console.log("fee from the contract IN USD", fee);

        return fee;
    }

    /// @notice Folows checks effects interaction
    /// @dev  though the price is in usd, pays in eth
    /// @param itemId is id of nft in this marketplace

    //need to transfer the royality and add the price can  change by the owner
    function buy(uint256 itemId) public payable nonReentrant {
        //checks
        MarketItem storage marketItem = idToMarketItem[itemId];
        address payable originalSeller = marketItem.sellerOrOwner;

        if (marketItem.sold) {
            revert NftMarketplace__AlreadySold(itemId);
        }
        if (marketItem.sellerOrOwner == msg.sender || marketItem.Creator == msg.sender) {
            revert NftMarketplace__CannotBuyHisToken(itemId);
        }
        //here not to the marketplace to the sellerOrOwner

        //royality to the creator
        uint256 priceToPay;
        uint256 royalityToPay;
        uint256 commissionInBuy;
        if (marketItem.isUsd) {
            royalityToPay = calculateMarketFeeForUsd(marketItem.price, marketItem.royalityForCreator);
            console.log("royality usd to from the contract", royalityToPay);
        } else {
            priceToPay = marketItem.price;
            royalityToPay = calculateMarketFeeForEth(marketItem.price, marketItem.royalityForCreator);
            console.log("royality usd to from the contract", royalityToPay);
        }

        if (marketItem.isUsd) {
            priceToPay = calculateUsdToPayPrice(marketItem.price);
            console.log("priceToPay in  the contract USD", priceToPay);
            commissionInBuy = calculateTheCommision(priceToPay);
            console.log(
                " FROM USD priceToPay + royalityToPay + commissionInBuy", priceToPay + royalityToPay + commissionInBuy
            );

            require(msg.value >= priceToPay + royalityToPay + commissionInBuy, "Insufficent Usd to buy");
        } else {
            priceToPay = (marketItem.price * PRECISION);
            console.log("priceToPay in eth the contract", priceToPay);
            commissionInBuy = calculateTheCommision(priceToPay);
            console.log(
                " FROM ETH priceToPay + royalityToPay + commissionInBuy", priceToPay + royalityToPay + commissionInBuy
            );
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
        (bool sellerSuccess,) = originalSeller.call{value: priceToPay}("");
        if (!sellerSuccess) revert NftMarketplace__BuyTransferFailed();

        //royality
        (bool royalityForCreatorSuccess,) = marketItem.Creator.call{value: royalityToPay}("");
        if (!royalityForCreatorSuccess) {
            revert NftMarketplace__BuyCreatorRoyalityTransferFailed();
        }

        INFT(nftContract).safeTransferFrom(address(this), msg.sender, marketItem.NftId);
    }

    /// @notice only for the tokens which has 18 decimals or 8 decimals
    /// @dev Buying the nft with existing erc
    /// @param itemId is the id of the nft in the marketplace
    /// @param token is the address of the token to buy the nft in the marketplace
    /// @param amount is how much tokens

    /*

      * need to take the amount of tokens as ethers.parseUnits("",18) from the frontend
    */
    /* 
    we have to take the   fee or commission from the user  and
     need to write for slippage protection */
    function buyTheNftWithErc(uint256 itemId, address token, uint256 amount) public nonReentrant {
        //checks
        console.log("from buyTheNftWithErc");
        console.log(" ");

        if (TokensPriceFeeds[token] == address(0)) {
            revert NftMarketplace__UnsupportedToken();
        }
        if (token == address(0)) {
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

        if (marketItem.sellerOrOwner == msg.sender || marketItem.Creator == msg.sender) {
            revert NftMarketplace__CannotBuyHisToken(itemId);
        }
        uint256 tokenDecimals = IERC20Metadata(token).decimals();
        uint256 price;
        uint256 priceFromUsdCalculation;
        if (marketItem.isUsd) {
            priceFromUsdCalculation = calculateUsdToPayPrice(marketItem.price);
            price = priceFromUsdCalculation * ADDITIONAL_PRECISION;
            console.log("price if usd ", price);
        } else {
            price = marketItem.price * PRECISION;
        }
        uint256 tokenToPay;
        uint256 royality;
        uint256 royalityToPay;
        uint256 commissionForBuyinWithErc;
        uint256 allWithPrecisions;

        //need to write interactions

        marketItem.sellerOrOwner = payable(msg.sender);

        //effects
        if (tokenDecimals == 18) {
            console.log(" from 18");

            // Logic for tokens with 18 decimals (most common, e.g., DAI, USDT, etc.)
            // Your logic here
            royality = calculateMarketFeeForEth(price, marketItem.royalityForCreator);
            console.log("marketItem.royalityForCreator from 18", marketItem.royalityForCreator); // in percentage

            console.log("royality from 18", royality); //40000000000000000

            tokenToPay = calculateTokenToEighteendecimals(price, token);
            console.log("tokenToPay from 18", tokenToPay);
            console.log("price from 18", price);
            console.log("token from 18", token);

            //    commissionForBuyinWithErc = calculateTheCommisionForErc(token);
            commissionForBuyinWithErc = (tokenToPay * commissionBasisPoints) / 10000;
            //40000000000000000
            royalityToPay = calculateTokenRoyality(tokenToPay, royality, token);
            console.log("royalityToPay from 18 contract", royalityToPay);
            console.log("commissionForBuyinWithErc from 18 contract", commissionForBuyinWithErc);
            //4000          //80
            console.log("total for 18", tokenToPay + royalityToPay + commissionForBuyinWithErc);
            allWithPrecisions = (tokenToPay * PRECISION) + (royalityToPay * PRECISION) + commissionBasisPoints;
            console.log("allWithPrecisions", allWithPrecisions);
            require(amount >= allWithPrecisions, "Insufficient payment amount from 18");
            bool success = IERC20Metadata(token).transferFrom(
                msg.sender, address(this), tokenToPay + royalityToPay + commissionForBuyinWithErc
            );
            require(success, "Transfer failed For 18 decimals");
        } else {
            console.log("from 8");

            // Logic for tokens with 8 decimals (e.g., WBTC, BTC)
            // Your logic here

            royality = calculateMarketFeeForEth(price, marketItem.royalityForCreator);
            console.log("marketItem.royalityForCreator from 8", marketItem.royalityForCreator);
            /*           for this function need to send the price  which come from the calcualtion
                so instead of price it is `priceFromUsdCalculation`
            */
            tokenToPay = calculateTokenToEightdecimals(priceFromUsdCalculation, token);
            console.log("tokenToPay from 8", tokenToPay);

            royalityToPay = calculateTokenRoyality(tokenToPay, royality, token);
            console.log("royalityToPay from 8 contract", royalityToPay);
            commissionForBuyinWithErc = calculateTheCommisionForErcForEight(token);
            console.log("total for 8", tokenToPay + royalityToPay + commissionForBuyinWithErc);
            allWithPrecisions =
                (tokenToPay * EIGHT_DECIMAL) + (royalityToPay * EIGHT_DECIMAL) + commissionForBuyinWithErc;

            console.log("tokenToPay * EIGHT_DECIMAL", tokenToPay * EIGHT_DECIMAL);
            console.log("royalityToPay * EIGHT_DECIMAL", royalityToPay * EIGHT_DECIMAL);
            console.log("commissionForBuyinWithErc", commissionForBuyinWithErc);

            console.log("allWithPrecisions from 8 contract", allWithPrecisions);
            require(amount >= allWithPrecisions, "Insufficient payment amount from 8");
            bool success = IERC20Metadata(token).transferFrom(
                msg.sender, address(this), tokenToPay + royalityToPay + commissionForBuyinWithErc
            );
            require(success, "Transfer failed For 8 decimals");
        }
        INFT(nftContract).safeTransferFrom(address(this), msg.sender, marketItem.NftId);
        emit MarketPlace_buyTheNftWithErc(
            itemId, marketItem.NftId, marketItem.Creator, originalSeller, royalityToPay, tokenToPay, tokenDecimals
        );
    }

    function calculateTheCommisionForErcForEight(address token) public view returns (uint256) {
        console.log(" from calculateTheCommisionForErcForEight");
        console.log(" ");

        address pricefeed = TokensPriceFeeds[token];
        if (pricefeed == address(0)) {
            revert NftMarketplace__TokenNotSupported(token);
        }
        (, int256 answer,,,) = AggregatorV3Interface(pricefeed).latestRoundData();
        // Check for valid price
        if (answer <= 0) {
            revert NftMarketplace__ZeroPriceFeed();
        }

        uint256 oneTokenInwei = (PRECISION) / (uint256(answer) / PRECISION);
        console.log("oneTokenInwei", oneTokenInwei);
        console.log(
            "((commissionForNftMarketplace  * uint (answer))/ PRECISION)",
            ((commissionForNftMarketplace * uint256(answer)) / (PRECISION * 10000))
        );

        //20_000_000_000_000
        // return((commissionForNftMarketplace  * uint(answer))/ PRECISION);
        uint256 NUmerator = commissionForBuyWithErc * uint256(answer);
        uint256 DEnominator = (PRECISION * 10000);
        uint256 conclusion = NUmerator / DEnominator;
        return conclusion;
    }
    /*  convert 1e14 ETH into tokens:-
    uint EthAmount = 1e14 to convert tokens
    so EthAmount * (price / 1 ether) = 1e14 * ((price)/ 1 ETH)
    FORMULA:- Total Tokens= ETH Amount * (tokens/ETH)

    and to convert to eth divide like this , to covert interms divide it interms of it
    like to convert to eth, divide it by eth.
          1e18 * (2000/ 1 eth) =  2000 tokens
    */

    function calculateTheCommisionForErc(address token) public view returns (uint256) {
        console.log(" from calculateTheCommisionForErc");
        console.log(" ");

        address pricefeed = TokensPriceFeeds[token];
        if (pricefeed == address(0)) {
            revert NftMarketplace__TokenNotSupported(token);
        }
        (, int256 answer,,,) = AggregatorV3Interface(pricefeed).latestRoundData();
        // Check for valid price
        if (answer <= 0) {
            revert NftMarketplace__ZeroPriceFeed();
        }

        /* 
     ikkada precision / anwser undali kaani ikkada price feed nunchi manam price 2000 * 1e18  use chesaamu 
     and ikkada  
        */
        uint256 oneTokenInwei = (PRECISION) / (uint256(answer) / PRECISION);
        console.log("oneTokenInwei", oneTokenInwei);
        console.log(
            "((commissionForNftMarketplace  * uint (answer))/ PRECISION)",
            ((commissionForNftMarketplace * uint256(answer)) / PRECISION)
        );
        /* 
                    1)How much ETH do I need for 2000 tokens?" → Divide 
                    2)"How many tokens do I get for 1 ETH?" → Multiply */

        return ((commissionForNftMarketplace * uint256(answer)) / PRECISION);
    }
    //given correct
    // 4000           royality in eth

    function calculateTokenRoyality(uint256 amountOfTokens, uint256 royality, address token)
        public
        view
        returns (uint256)
    {
        console.log("from calculateTokenRoyality");
        console.log(" ");

        address pricefeed = TokensPriceFeeds[token];
        if (pricefeed == address(0)) {
            revert NftMarketplace__TokenNotSupported(token);
        }
        (, int256 answer,,,) = AggregatorV3Interface(pricefeed).latestRoundData();
        // Check for valid price
        if (answer <= 0) {
            revert NftMarketplace__ZeroPriceFeed();
        }
        // Check for valid price
        if (amountOfTokens <= 0) {
            revert NftMarketplace__ZeroTokensForCalulatingRoyality();
        }

        // Check for valid price
        if (royality <= 0) {
            revert NftMarketplace__ZeroRoyality();
        }

        /* 
           1) answer ni precision tho dvide chesthuannam
            because it gives like this 2000*1e18 so we need to get the actual price
        2)ikkada preciosion ni price tho divide chesthunnam to get value of one token in wei  */
        uint256 oneTokenInwei = (PRECISION) / (uint256(answer) / PRECISION);
        // console.log("royality from the contract", (royality));

        // console.log("(amountOfTokens * royality)  from the contract",(amountOfTokens * PRECISION ));
        // console.log("(PERCENT * PRECISION)  from the contract",(PERCENT * royality));

        console.log("oneTokenInwei from  calculateTokenRoyality", oneTokenInwei); //500000000000000
        console.log("royality / (PRECISION * oneTokenInwei", royality / (PRECISION * oneTokenInwei));
        console.log("answer", uint256(answer));
        return (royality / (PRECISION * oneTokenInwei)); //given correct need to change in test
    }

    function calculateTokenToEighteendecimals(uint256 Nftprice, address token) public view returns (uint256) {
        console.log("calculateTokenToEighteendecimals");

        address pricefeed = TokensPriceFeeds[token];
        if (pricefeed == address(0)) {
            revert NftMarketplace__TokenNotSupported(token);
        }
        (, int256 answer,,,) = AggregatorV3Interface(pricefeed).latestRoundData();
        // Check for valid price
        if (answer <= 0) {
            revert NftMarketplace__ZeroPriceFeed();
        }
        //price 1eth = 2dai
        //eth = 2/1 dai
        console.log("(Nftprice * PRECISION)  from the contract", (Nftprice * PRECISION));
        //4_000_000_000_000_000_000_000_000_000_000_000_000
        console.log("(Nftprice)  from the contract", (Nftprice)); //2_000_000_000_000_000_000

        console.log("answer  from the contract calculateTokenToEighteendecimals", uint256(answer)); //1_000_000_000_000_000

        //2000 1e18 * 1e18              //6 1e18
        uint256 amount = (uint256(answer) * Nftprice) / (PRECISION * PRECISION); //2000000000000000000000
        console.log("amount  from the contract", amount); //1_000_000_000_000_000

        return amount;
    }

    function calculateTokenToEightdecimals(uint256 Nftprice, address token) public view returns (uint256) {
        console.log("calculateTokenToEightdecimals");
        address pricefeed = TokensPriceFeeds[token];
        if (pricefeed == address(0)) {
            revert NftMarketplace__TokenNotSupported(token);
        }
        (, int256 answer,,,) = AggregatorV3Interface(pricefeed).latestRoundData();
        // Check for valid price
        if (answer <= 0) {
            revert NftMarketplace__ZeroPriceFeed();
        }
        console.log("(Nftprice * PRECISION)  from the contract", (Nftprice * PRECISION));
        //4_000_000_000_000_000_000_000_000_000_000_000_000
        console.log("(Nftprice)  from the contract", (Nftprice)); //2_000_000_000_000_000_000

        console.log("answer  from the contract calculateTokenToEightdecimals", uint256(answer)); //1_000_000_000_000_000
            //2000 1e18 * 1e18              //6 1e18
        uint256 amount = (uint256(answer) * ADDITIONAL_PRECISION * Nftprice) / (PRECISION * PRECISION); //2000000000000000000000
        console.log("amount  from the contract", amount); //1_000_000_000_000_000
        return amount;
    }

    function reListInTheMarket(uint256 _itemId, uint256 _price, bool _isUsd) public payable {
        console.log("reListInTheMarket");
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
        uint256 feeTopay;
        if (_isUsd) {
            feeTopay = calculateMarketFeeForUsd(_price, marketItem.royalityForCreator);
            require(msg.value >= feeTopay, "Insuffient Usd for Listing");
        } else {
            feeTopay = calculateMarketFeeForEth(_price, marketItem.royalityForCreator);
            console.log("feeTopay", feeTopay);
            require(msg.value >= feeTopay, "Insuffient Eth for Listing");
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

    function checkItExits(uint256 _ItemId) public view returns (bool) {
        return _ItemId > 0 && _ItemId <= ItemId;
    }

    function calculateUsdToPayPrice(uint256 priceInUsd) public view returns (uint256) {
        console.log("calculateUsdToPayPrice");
        uint256 priceFromPricefeed = priceFromethUsdpriceFeed();
        uint256 priceFromPriceFeedInEth = priceFromPricefeed * ADDITIONAL_PRECISION;
        uint256 priceInUsdToEth = priceInUsd * PRECISION;
        uint256 priceToPay = (priceInUsdToEth * PRECISION) / priceFromPriceFeedInEth;
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

    function calculateTheCommision(uint256 price) public view returns (uint256) {
        console.log("calculateTheCommision");

        uint256 intermediateStep1 = price * commissionForNftMarketplace;
        console.log("intermediateStep1:", intermediateStep1);

        uint256 intermediateStep2 = PERCENT * PRECISION;
        console.log("intermediateStep2:", intermediateStep2);

        uint256 intermediateStep3 = intermediateStep1 / intermediateStep2;
        console.log("intermediateStep3:", intermediateStep3);

        uint256 intermediateStep4 = intermediateStep3 * PRECISION / 1e16;
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

    function getPRECISION() public view returns (uint256) {
        return PRECISION;
    }

    function getidToMarketItem(uint256 tokendId) public view returns (MarketItem memory) {
        return idToMarketItem[tokendId];
    }

    function getethUsdpriceFeed() public view returns (address) {
        return address(ethUsdpriceFeed);
    }

    function getAllMarketItems() public view returns (MarketItem[] memory) {
        MarketItem[] memory items = new MarketItem[](ItemId);
        uint256 itemid = ItemId;
        console.log("itemid from the contract", itemid);
        //2
        for (uint256 i = 0; i < itemid; i++) {
            items[i] = idToMarketItem[i + 1];
        }
        return items;
    }

    function priceFromethUsdpriceFeed() public view returns (uint256) {
        (, int256 answer,,,) = ethUsdpriceFeed.latestRoundData();

        return uint256(answer);
    }

    function creatorOfNft(uint256 tokenId) public view returns (address) {
        address creator = idToMarketItem[tokenId].Creator;
        return creator;
    }

    function sellerOrownerOfNft(uint256 tokenId) public view returns (address) {
        address sellerOrOwner = idToMarketItem[tokenId].sellerOrOwner;
        return sellerOrOwner;
    }
}
