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
  const priceForUsd = 4000

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

      await nftMarketplace.connect(deployer).createMarketItem(1,price1,royality1,false,{value: ethers.parseUnits("0.04")})
      const Array = await nftMarketplace.getmarketItemsLength() 
      
      expect(Array).to.be.equal(1)
})


         it("testing the mapping  in marketplace",async() => {           
        const Array = await nftMarketplace.getidToMarketItem(1)
        expect(Array[0]).to.be.equal(BigInt(1))
           expect(Array[1]).to.be.equal(BigInt(1))
           expect(Array[2]).to.be.equal(deployer.address)
           expect(Array[3]).to.be.equal("0x0000000000000000000000000000000000000000")
           expect(Array[4]).to.be.equal(BigInt(2))
           expect(Array[5]).to.be.equal(BigInt(2))
           expect(Array[6]).to.be.equal(false)




  
           })
   
           it("testing the createMarketItem in marketplace for usd",async() => {   
            const Tx =  await nft.connect(deployer).mint(tokenURI)
            const TxReceipt = await Tx.wait()
            await nft.connect(deployer).approve(nftMarketplace.target,2)


            const fee = await nftMarketplace.calculateMarketFeeForUsd(priceForUsd,royality1)
            console.log("fee for the usd",fee);
            
            await nftMarketplace.connect(deployer).createMarketItem(2,priceForUsd,royality1,true,{value: ethers.parseUnits("0.04")})
            const Array = await nftMarketplace.getmarketItemsLength()
            
            expect(Array).to.be.equal(2)
      })

    })
  
       

        
 
});