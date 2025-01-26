const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat")

describe("DEPLOYMENT", async () => {

  /////////////
  //  LET    //
  ////////////
  let deployer,user,nft,nftMarketplace,mockV3Aggregator


  /////////////
  //  CONST    //
  ////////////
  const address1 ='0x0000000000000000000000000000000000000001'
  const name = "Undefeated"
  const symbol = "UDF"
  const tokenURI = "tokenUri"
  const price = ethers.parseEther("10")
  const royality1 = 2 
  const price1 = 2
  const DECIMALS = 8;
  const ETH_USD_PRICE = 200000000000;
  const priceForUsd = 5500

  before( async ()=> {
    const NFT = await ethers.getContractFactory("NFT")
         nft = await NFT.deploy();
        [deployer,user]  = await ethers.getSigners()
        const MockV3Aggregator = await ethers.getContractFactory("MockV3Aggregator");
        mockV3Aggregator = await MockV3Aggregator.connect(deployer).deploy(DECIMALS,ETH_USD_PRICE);
  
        const NftMarketplace = await ethers.getContractFactory("NftMarketplace")
        nftMarketplace = await NftMarketplace.deploy(nft.target,mockV3Aggregator.target)
})

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
      const fee = await nftMarketplace.calculateMarketFeeForEth(price1,royality1)
      console.log("fee for the ETH",fee);

     const Tx = await nftMarketplace.connect(deployer).createMarketItem(1,price1,royality1,false,{value: ethers.parseUnits("0.04")})
     const TxReceipt = await Tx.wait()
       const logs = TxReceipt.logs[0]
      const args = logs.args
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
            await nft.connect(deployer).approve(nftMarketplace.target,2)


            const fee = await nftMarketplace.calculateMarketFeeForUsd(priceForUsd,royality1)
            console.log("fee for the usd test HERE",fee);
            
            const TxCreate =  await nftMarketplace.connect(deployer).createMarketItem(2,priceForUsd,royality1,true,{value: ethers.parseEther("0.055")})
            const TxCreateReceipt = await TxCreate.wait()
            const logs = TxCreateReceipt.logs[0]
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
        // console.log("ARRAY 2",Array);

        expect(Array[0]).to.be.equal(2)
        expect(Array[1]).to.be.equal(2)
        expect(Array[2]).to.be.equal(deployer.address)
        expect(Array[3]).to.be.equal(deployer.address)
        expect(Array[4]).to.be.equal(2)
        expect(Array[5]).to.be.equal(5500) //here


        expect(Array[6]).to.be.equal(true)

      })

      describe('BUY IN MARKETPLACE', () => { 
         it("BUY First NFT",async () => {
               const contractBalance = await ethers.provider.getBalance(nftMarketplace.target)
               const deployerBalance = await ethers.provider.getBalance(deployer.address)
               const UserBalance = await ethers.provider.getBalance(user.address) 
              //  console.log("contractBalance",contractBalance); //0.08 
              //  console.log("deployerBalance",deployerBalance);//9999.908586230462626495
              //  console.log("UserBalance",UserBalance);//10000
              await nft.connect(deployer).approve(nftMarketplace.target,1)

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

          const fee = await nftMarketplace.calculateMarketFeeForUsd(priceForUsd,royality1)
          console.log("fee for the usd test HERE in 2nd id",fee);
          await nft.connect(deployer).approve(nftMarketplace.target,2)

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
              await  expect( nftMarketplace.connect(user).reListInTheMarket(1,4,false)).to.be.revertedWith("Insuffient Eth for Listing")

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
       



      })

    })

    })
  // //given 27500_000_000_000_000
  // // need 275_000_000_000_000
             
  //         275000_000_000_000
  // //        2_750_000_000_000
  // //2750_000_000_000

  //1000000000000000
  //1000000000000000

  //10100000000000000
  //10100000000000000

  //10000000000000000000
  //10000000000000000000


 //git commit m "completed test commission and all"