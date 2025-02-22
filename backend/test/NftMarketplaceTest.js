const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat")


/* giving an error of the ERC20: insufficient allowance  */
describe("DEPLOYMENT", async () => {
  /////////////
  //  LET    //
  ////////////
  let deployer, user, nft, nftMarketplace,
   mockV3Aggregator, user1, dai, wBtc, staking, rewardToken;

  /////////////
  //  CONST  //
  ////////////
  const address1 = '0x0000000000000000000000000000000000000001'
  const name = "Undefeated"
  const symbol = "UDF"
  const tokenURI = "tokenUri"
  const price = ethers.parseEther("10")
  const royality1 = 2  // in percentage
  const price1 = 2
  const DECIMALS = 8;
  const DECIMALSFOREIGHTEEN = 18
  const ETH_USD_PRICE = 200000000000;
  const largeNumberStr = "2000000000000000000000";
  const ETH_DAI_PRICE = BigInt(largeNumberStr);
  const REWARDTOKEN = 1000000
  const priceForUsd = 5500

  before(async () => {
    // Get signers first
    [deployer, user, user1] = await ethers.getSigners()

      ////////////////////////////
    // Deploy NFT              //
    ///////////////////////////
    const NFT = await ethers.getContractFactory("NFT")
    nft = await NFT.deploy();
    await nft.waitForDeployment();

      ////////////////////////////
    // Deploy MockV3Aggregator //
    ///////////////////////////
    const MockV3Aggregator = await ethers.getContractFactory("MockV3Aggregator");
    mockV3Aggregator = await MockV3Aggregator.connect(deployer).deploy(DECIMALS, ETH_USD_PRICE);
    await mockV3Aggregator.waitForDeployment();

      ////////////////////////////
    // Deploy RewardToken      //
    ///////////////////////////
    const RewardToken = await ethers.getContractFactory("RewardToken");
    rewardToken = await RewardToken.deploy("RewardToken", "RT", deployer.address, 0);
    await rewardToken.waitForDeployment();

      ////////////////////////////
    // Deploy Staking         //
    ///////////////////////////
    const Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(
      await rewardToken.getAddress(),
      ethers.ZeroAddress
    );
    await staking.waitForDeployment();

    
      ////////////////////////////
    // Deploy Mock Tokens     //
    ///////////////////////////
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const ERC20MockEight = await ethers.getContractFactory("ERC20MockEight");

    dai = await ERC20Mock.connect(user1).deploy("DAI_COIN", "DAI", user1.address, 1000);
    await dai.waitForDeployment();

    wBtc = await ERC20MockEight.connect(user1).deploy("WBTC_COIN", "WBTC", user1.address, 1000);
    await wBtc.waitForDeployment();

    ////////////////////////////
    // Deploy NftMarketplace //
    ///////////////////////////
    const NftMarketplace = await ethers.getContractFactory("NftMarketplace");
    nftMarketplace = await NftMarketplace.deploy(
      await nft.getAddress(),
      await mockV3Aggregator.getAddress(),
      [await dai.getAddress(), await wBtc.getAddress()],
      [await mockV3Aggregator.getAddress(), await mockV3Aggregator.getAddress()],
      await staking.getAddress()
    );
    await nftMarketplace.waitForDeployment();

    // Update Staking with the actual NftMarketplace address
    await staking.setMarketplace(await nftMarketplace.getAddress());
  });

  // Add at least one test case


   describe('NFT', () => {   
 
  it("testing the tokenId",async  ()=>{
   const id =  await nft.getTokenId()
      expect(id).to.be.equal(0)
  })

  it("testing the name and symbol",async  ()=>{
  const nftName =  await nft.name()
  const nftsymbol =  await nft.symbol()
    expect(nftName).to.be.equal(name)
    expect(nftsymbol).to.be.equal(symbol)
   })

   it("testing the MINT and its EVENTS ",async  ()=>{
     const Tx =  await nft.connect(deployer).mint(tokenURI)
     const TxReceipt = await Tx.wait()
     //second event is logs[1],first event is logs[0]
     const logs  = TxReceipt.logs[2];
       const args = logs.args
      
       

       //tested getter
     let id =  await nft.getTokenId()
     let Owner = await nft.ownerOf(id)
     expect(args[0]).to.be.equal(deployer)
     expect(args[0]).to.be.equal(Owner)
       expect(args[1]).to.be.equal(1)
       const error = "NFT__TokenURIIsEmpty"
   await expect(
     nft.mint("")
           ).to.be.revertedWithCustomError(nft, "NFT__TokenURIIsEmpty");

         const uri = await nft.tokenURI(1)
           expect(uri).to.be.equal(tokenURI)

      })


           })
      describe('MARKETPLACE', () => { 
        it("testing the nft in marketplace",async() => {
              const nftcontract = await nftMarketplace.getNftContractAddress()
              expect(nftcontract).to.be.equal(nft)
        })

        it("testing the approve in marketplace",async() => {
          const YorN = await nftMarketplace.VerifyTheApproved(1)
          expect(YorN).to.be.equal(true)
          await nft.connect(deployer).approve(nftMarketplace.target,1)
          const TorF = await nft.connect(deployer).ownerOf(1)
          //  console.log("TorF",TorF);
          //  await nftMarketplace.connect(deployer).ApproveForcreateMarketItem(1)
      
          const YorN2 = await nftMarketplace.VerifyTheApproved(1)
          expect(YorN2).to.be.equal(false)
    })
    it("testing the createMarketItem in marketplace for eth",async() => {           
      // const fee = await nftMarketplace.calculateMarketFeeForEth(price1,royality1)
      // console.log("fee for the ETH",fee);
                                                                     //   in ether
     const Tx = await nftMarketplace.connect(deployer).createMarketItem(1,price1,royality1,false,{value: ethers.parseUnits("0.04")})
     const TxReceipt = await Tx.wait()
       const logs = TxReceipt.logs[1]
      const args = logs.args
      // console.log("args",args);
      
      expect(args[0]).to.be.equal(BigInt(1))
      expect(args[1]).to.be.equal(BigInt(1))
      expect(args[2]).to.be.equal(deployer.address)
      expect(args[3]).to.be.equal(deployer.address)
      expect(args[4]).to.be.equal(BigInt(2))
      expect(args[5]).to.be.equal(BigInt(2))
      expect(args[6]).to.be.equal(false)
      expect(args[7]).to.be.equal(false)
      const Array = await nftMarketplace.getAllMarketItems() 
      // console.log("ARRAY",Array);
      
      
      // expect(Array).to.be.equal(1)

})
    it("testing the mapping  in marketplace",async() => {           
        const Array = await nftMarketplace.getidToMarketItem(1)
        expect(Array[0]).to.be.equal(BigInt(1))
           expect(Array[1]).to.be.equal(BigInt(1))
           expect(Array[2]).to.be.equal(deployer.address)
           expect(Array[3]).to.be.equal(deployer.address)
           expect(Array[4]).to.be.equal(BigInt(2))
           expect(Array[5]).to.be.equal(BigInt(2))
           expect(Array[6]).to.be.equal(false)
           })
   
           it("testing the createMarketItem in marketplace for usd",async() => {   
            const Tx =  await nft.connect(deployer).mint(tokenURI)
            const TxReceipt = await Tx.wait()

            await nft.connect(deployer).approve(nftMarketplace.target, 2); // Approve token ID 2


            // const fee = await nftMarketplace.calculateMarketFeeForUsd(priceForUsd,royality1)
            // console.log("fee for the usd test HERE",fee);
            
            const TxCreate =  await nftMarketplace.connect(deployer).createMarketItem(2,priceForUsd,royality1,true,{value: ethers.parseEther("0.055")})
            const TxCreateReceipt = await TxCreate.wait()
            const logs = TxCreateReceipt.logs[1]
            const args = logs.args
            expect(args[0]).to.be.equal(BigInt(2))
            expect(args[1]).to.be.equal(BigInt(2))
            expect(args[2]).to.be.equal(deployer.address)
            expect(args[3]).to.be.equal(deployer.address)
            expect(args[4]).to.be.equal(BigInt(2))
            expect(args[5]).to.be.equal(BigInt(5500)) //here
            expect(args[6]).to.be.equal(true)
            expect(args[7]).to.be.equal(false)
            
            const getAllMarketItems = await nftMarketplace.getAllMarketItems();
            // console.log("getAllMarketItems from the test",getAllMarketItems);
            // // Add these new assertions
            expect(getAllMarketItems.length).to.equal(2);  
      })

      it("it should revert when the price createMarketItem in marketplace for usd is 0", async () =>{
        await expect(nftMarketplace.createMarketItem(2,0,royality1,true,{value: ethers.parseUnits("0.04")})).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__PriceIsZero")

      })
      it("it should revert when  the royality of createMarketItem in marketplace for usd is 0", async () =>{
        await expect(nftMarketplace.createMarketItem(2,priceForUsd,0,true,{value: ethers.parseUnits("0.04")})).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__RoyalityCreator")

      })
      it("it should revert when  the fee of createMarketItem in marketplace for eth is 0", async () =>{
        await expect(
          nftMarketplace.createMarketItem(2,price,royality1,false,{value: 0 })
      ).to.be.revertedWith("pay the fee for price in eth")

      })

      it("it should revert when  the fee of createMarketItem in marketplace for usd is 0", async () =>{
        await expect(
          nftMarketplace.createMarketItem(2,priceForUsd,royality1,true,{value: 0 })
      ).to.be.revertedWith("pay the fee for price in usd")
      })

      it("it should test getAllMarketItems",async()=>{
        let ArrayStwo = await nftMarketplace.getAllMarketItems() 
        let Array = ArrayStwo[0]
        // console.log("ARRAY",Array);
        expect(Array[0]).to.be.equal(1)
        expect(Array[1]).to.be.equal(1)
        expect(Array[2]).to.be.equal(deployer.address)
        expect(Array[3]).to.be.equal(deployer.address)
        expect(Array[4]).to.be.equal(2)
        expect(Array[5]).to.be.equal(2)
        expect(Array[6]).to.be.equal(false)

        Array = ArrayStwo[1]

        expect(Array[0]).to.be.equal(2)
        expect(Array[1]).to.be.equal(2)
        expect(Array[2]).to.be.equal(deployer.address)
        expect(Array[3]).to.be.equal(deployer.address)
        expect(Array[4]).to.be.equal(2)
        expect(Array[5]).to.be.equal(5500) //here


        expect(Array[6]).to.be.equal(true)

      })

      describe('BUY AND RELIST IN MARKETPLACE', async () => { 
         it("BUY First NFT",async () => {
               const contractBalance = await ethers.provider.getBalance(nftMarketplace.target)
               const deployerBalance = await ethers.provider.getBalance(deployer.address)
               const UserBalance = await ethers.provider.getBalance(user.address) 
              //  console.log("contractBalance",contractBalance); //0.08 
              //  console.log("deployerBalance",deployerBalance);//9999.908586230462626495
              //  console.log("UserBalance",UserBalance);//10000
            
              await nftMarketplace.connect(user).buy(1,{value:ethers.parseEther("2.0402")})

              const contractBalanceAfter = await ethers.provider.getBalance(nftMarketplace.target)
              const deployerBalanceAfter = await ethers.provider.getBalance(deployer.address)
              const UserBalanceAfter = await ethers.provider.getBalance(user.address) 
              // console.log("contractBalanceAfter",contractBalanceAfter);//2.039999999999999998
              // console.log("deployerBalanceAfter",deployerBalanceAfter);//9999.948586230462626495
              // console.log("UserBalanceAfter",UserBalanceAfter);//9997.999845979240190298
              // console.log("contractBalanceAfter -contractBalance",contractBalanceAfter -contractBalance);
              // console.log("deployerBalanceAfter -deployerBalance",deployerBalanceAfter -deployerBalance);
              // console.log(" UserBalance - UserBalanceAfter", UserBalance - UserBalanceAfter);
              expect(contractBalanceAfter).to.be.greaterThan(contractBalance)
              expect(deployerBalanceAfter).to.be.greaterThan(deployerBalance)
              expect(UserBalance).to.be.greaterThan(UserBalanceAfter)



         })
         it("BUY Second NFT",async () => {
          const contractBalance = await ethers.provider.getBalance(nftMarketplace.target)
          const deployerBalance = await ethers.provider.getBalance(deployer.address)
          const UserBalance = await ethers.provider.getBalance(user.address) 
          console.log("contractBalance",contractBalance); //0.08 
          console.log("deployerBalance",deployerBalance);//9999.908586230462626495
          console.log("UserBalance",UserBalance);//10000

          // const fee = await nftMarketplace.calculateMarketFeeForUsd(priceForUsd,royality1)
          // console.log("fee for the usd test HERE in 2nd id",fee);
         await nftMarketplace.connect(user).buy(2,{value:ethers.parseEther("2.805276")}) // ONLY FEE + PRICE ,COMMISSION NOT ADDED

         const contractBalanceAfter = await ethers.provider.getBalance(nftMarketplace.target)
         const deployerBalanceAfter = await ethers.provider.getBalance(deployer.address)
         const UserBalanceAfter = await ethers.provider.getBalance(user.address) 
         console.log("contractBalanceAfter",contractBalanceAfter);//2.039999999999999998
         console.log("deployerBalanceAfter",deployerBalanceAfter);//9999.948586230462626495
         console.log("UserBalanceAfter",UserBalanceAfter);//9997.999845979240190298
         console.log("contractBalanceAfter -contractBalance",contractBalanceAfter -contractBalance);
         console.log("deployerBalanceAfter -deployerBalance",deployerBalanceAfter -deployerBalance);
         console.log(" UserBalance - UserBalanceAfter", UserBalance - UserBalanceAfter);
         expect(contractBalanceAfter).to.be.greaterThan(contractBalance)
         expect(deployerBalanceAfter).to.be.greaterThan(deployerBalance)
         expect(UserBalance).to.be.greaterThan(UserBalanceAfter)
    })
    it(" test for USD commission ",async () => {
      const commissionForUSD = await nftMarketplace.calculateTheCommision(ethers.parseEther("2.75"))

      //GIVING CORRECT ANSWER
       expect(275000000000000).to.be.equal(commissionForUSD)


       })
       it(" test for ETH commission ",async () => {
        const commissionFORETH = await nftMarketplace.calculateTheCommision(ethers.parseEther("2"))
         expect( 200000000000000).to.be.equal(commissionFORETH)
  
         })
      
      it(" test for reListInTheMarket for First Nft ",async () => {

          const Tx = await nftMarketplace.connect(user).reListInTheMarket(1,4,false,{value: ethers.parseEther("0.08")})
           const TxCreateReceipt = await Tx.wait()
            const logs =TxCreateReceipt.logs[0]
            const args = logs.args
            expect(args[0]).to.be.equal(BigInt(1))
            expect(args[1]).to.be.equal(BigInt(1))
            expect(args[2]).to.be.equal(deployer.address)
            expect(args[3]).to.be.equal(user.address)
            expect(args[4]).to.be.equal(BigInt(2))
            expect(args[5]).to.be.equal(BigInt(4))
            expect(args[6]).to.be.equal(false)
            expect(args[7]).to.be.equal(false)

            const Array= await nftMarketplace.getidToMarketItem(1)
            expect(Array[0]).to.be.equal(BigInt(1))
            expect(Array[1]).to.be.equal(BigInt(1))
            expect(Array[2]).to.be.equal(deployer.address)
            expect(Array[3]).to.be.equal(user.address)
            expect(Array[4]).to.be.equal(BigInt(2))
            expect(Array[5]).to.be.equal(BigInt(4))
            expect(Array[6]).to.be.equal(false)
            expect(Array[7]).to.be.equal(false)
           })

           it(" test for reListInTheMarket for First Nft  to Revert For not giving Price",async () => {
              
              await expect(nftMarketplace.connect(user).reListInTheMarket(1,4,false)).to.be.revertedWith("Insuffient Eth for Listing");

           })
           it(" test for reListInTheMarket for First Nft  to Revert for not Exits",async () => {
            await  expect( nftMarketplace.connect(user).reListInTheMarket(10,4,false)).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__NotExist")

         })
         it(" test for reListInTheMarket for First Nft  to Revert for not Exits",async () => {
          await  expect( nftMarketplace.connect(user).reListInTheMarket(1,0,false)).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__PriceIsZero")

       })
       it(" test for reListInTheMarket for First Nft  to Revert for not the seller",async () => {
        await  expect( nftMarketplace.connect(deployer).reListInTheMarket(1,0,false)).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__NotTheSellerOrOwner")
     })

     it(" test for reListInTheMarket for Second Nft ",async () => {
      const Tx = await nftMarketplace.connect(user).reListInTheMarket(2,11000,true,{value: ethers.parseEther("0.11")})
       const TxCreateReceipt = await Tx.wait()
        const logs =TxCreateReceipt.logs[0]
        const args = logs.args
        expect(args[0]).to.be.equal(BigInt(2))
        expect(args[1]).to.be.equal(BigInt(2))
        expect(args[2]).to.be.equal(deployer.address)
        expect(args[3]).to.be.equal(user.address)
        expect(args[4]).to.be.equal(BigInt(2))
        expect(args[5]).to.be.equal(BigInt(11000))
        expect(args[6]).to.be.equal(true)
        expect(args[7]).to.be.equal(false)

        const Array= await nftMarketplace.getidToMarketItem(2)
        expect(Array[0]).to.be.equal(BigInt(2))
        expect(Array[1]).to.be.equal(BigInt(2))
        expect(Array[2]).to.be.equal(deployer.address)
        expect(Array[3]).to.be.equal(user.address)
        expect(Array[4]).to.be.equal(BigInt(2))
        expect(Array[5]).to.be.equal(BigInt(11000))
        expect(Array[6]).to.be.equal(true)
        expect(Array[7]).to.be.equal(false)
       })

       it(" test for reListInTheMarket for Second Nft  to Revert For not giving Price",async () => {
          await  expect( nftMarketplace.connect(user).reListInTheMarket(2,11000,true)).to.be.revertedWith("Insuffient Usd for Listing")

       })
       it(" test for reListInTheMarket for Second Nft  to Revert for not Exits",async () => {
        await  expect( nftMarketplace.connect(user).reListInTheMarket(10,11000,true)).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__NotExist")

     })
     it(" test for reListInTheMarket for Second Nft  to Revert for not Exits",async () => {
      await  expect( nftMarketplace.connect(user).reListInTheMarket(2,0,true)).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__PriceIsZero")

   })
   it(" test for reListInTheMarket for Second Nft  to Revert for not the seller",async () => {
    await  expect( nftMarketplace.connect(deployer).reListInTheMarket(2,0,true)).to.be.revertedWithCustomError(nftMarketplace,"NftMarketplace__NotTheSellerOrOwner")
 })
      
      })
      describe('Buy The Nft With ERC20', () => { 

        it(" For calualting EIGHT",async() => {
          await mockV3Aggregator.updateAnswer(150000000000)
          // Destructure the tuple, capturing only the 'answer' (second element)
                const [, answer] = await mockV3Aggregator.latestRoundData();
                  console.log( "answer ETH_DAI_PRICE eight",answer);                                           //12 000
                        const withErc =  await  nftMarketplace.calculateTokenToEightdecimals(ethers.parseEther("4"),dai.target)
                        console.log("withErc",withErc)
                      })
        it(" For calualting EIGHTEEN", async() => {

          // Destructure the tuple, capturing only the 'answer' (second element)
      await mockV3Aggregator.updateAnswer(ETH_DAI_PRICE)
      const [, answer] = await mockV3Aggregator.latestRoundData();

     const price =  await mockV3Aggregator.getAnswer(ETH_DAI_PRICE)

              console.log( "answer ETH_DAI_PRICE",answer);                                           //12 000
              const withErc =  await  nftMarketplace.calculateTokenToEighteendecimals(ethers.parseEther("2"),dai.target)
              console.log("withErc",withErc);
            })


        it("BUY TEST FOR 18",async ()=>{

          const TxNft =  await nft.connect(deployer).mint(tokenURI)
          const TxNftReceipt = await TxNft.wait()

          const daiAmountToMint = ethers.parseUnits("1000000", 18); // Minting 100 DAI
          await dai.connect(deployer).mint(user.address, daiAmountToMint);
         
          // Replace with something like:
          await dai.connect(user).approve(nftMarketplace.target,ethers.MaxUint256);
          await nft.connect(deployer).approve(nftMarketplace.target, 3)

          const TxCreate = await nftMarketplace.connect(deployer).createMarketItem(3,price1,royality1,false,{value: ethers.parseUnits("0.04")})
          const TxCreateReceipt = await TxCreate.wait()
          
          const Tx = await nftMarketplace.connect(user).buyTheNftWithErc(3,dai.target,ethers.parseUnits("4160", 18))
          const TxReceipt = await Tx.wait()

        })

          // givng error for the  approves ones
          it("BUY TEST FOR 8",async ()=>{

            const TxNft =  await nft.connect(deployer).mint(tokenURI)
            const TxNftReceipt = await TxNft.wait()
  
            const daiAmountToMint = ethers.parseUnits("1000000", 8); // Minting 100 DAI
            await wBtc.connect(deployer).mint(user.address, daiAmountToMint);
           
            // Replace with something like:
            await wBtc.connect(user).approve(nftMarketplace.target,ethers.MaxUint256);
            await nft.connect(deployer).approve(nftMarketplace.target,4)
  
            const TxCreate = await nftMarketplace.connect(deployer).createMarketItem(4,4000,royality1,true,{value: ethers.parseUnits("0.04")})
            const TxCreateReceipt = await TxCreate.wait()

            const Tx = await nftMarketplace.connect(user).buyTheNftWithErc(4,wBtc.target,ethers.parseUnits("4080.00002", 8))
            const TxReceipt = await Tx.wait()
          })
       })
 
    })

    })
 