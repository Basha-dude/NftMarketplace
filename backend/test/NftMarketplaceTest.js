const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("DEPLOYMENT", async () => {

  /////////////
  //  LET    //
  ////////////
  let deployer,user,nft


  /////////////
  //  CONST    //
  ////////////
  const address1 ='0x0000000000000000000000000000000000000001'
  const name = "Undefeated"
  const symbol = "UDF"
  const tokenURI = "tokenUri"


  before( async ()=> {
       const NFT = await ethers.getContractFactory("NFT")
            nft = await NFT.deploy();
           [deployer,user]  = await ethers.getSigners()
  })
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
        const Tx =  await nft.mint(tokenURI)
        const TxReceipt = await Tx.wait()

        const logs  = TxReceipt.logs[1];
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

         })

         const uri = await nft.tokenURI(1)

         expect(uri).to.be.equal(tokenURI)

        
 
});
