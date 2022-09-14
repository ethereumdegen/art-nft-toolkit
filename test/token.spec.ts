 
import chai, { expect } from 'chai'
import chaiAsPromised from 'chai-as-promised'
 
import { BigNumber, utils, Wallet } from 'ethers'

import hre, { ethers, getNamedAccounts ,getNamedSigner} from 'hardhat'
 
//import { deploy } from 'helpers/deploy-helpers'
import { UndergroundArt } from '../generated/typechain'
import { deploy } from '../helpers/deploy-helpers'
import { generateArtSignature, generateRandomNonce } from './lib/art-signature-tools'
import { createAndFundRandomWallet } from './lib/test-utils' 
 


chai.should()
chai.use(chaiAsPromised)

const {   deployments } = hre

// eslint-disable-next-line @typescript-eslint/no-empty-interface
interface SetupOptions {}

interface SetupReturn {
  artContract: UndergroundArt 
}

const setup = deployments.createFixture<SetupReturn, SetupOptions>(
  async (hre, _opts) => {
   
   
    await hre.deployments.fixture(['primary'], {
      keepExistingDeployments: false,
    })

    const artContract = await hre.contracts
    .get<UndergroundArt>('UndergroundArt')

    return {
      artContract
    }
  }
)



describe('Upgrade Contract', () => {

  let artContract: UndergroundArt 
  
  let deployer: Wallet
  let artist: Wallet 
  let minter: Wallet  

    before(async () => {
      
      deployer = await getNamedSigner('deployer')

      artist = await createAndFundRandomWallet( ethers.provider )
      minter = await createAndFundRandomWallet( ethers.provider )
     
      //let minerEth = await miner.getBalance()

      const result = await setup()
      artContract = result.artContract

     })


  

    it('should create a project', async () => { 

    
      console.log('deployer',await deployer.getAddress())

      let artistAddress = await artist.getAddress()
      let metadataURI = "ipfs://"
      let totalSupply = 10

      await artContract.connect(deployer).defineProject(
        artistAddress,
        metadataURI,
        totalSupply
      )

      let projectData = await artContract.artProjects(0);
 

      projectData.artistAddress.should.eql(artistAddress)
      projectData.metadataURI.should.eql(metadataURI)
      projectData.totalSupply.should.eql(totalSupply)
      
    })
  
    it('should mint a token', async () => { 

      let chainId = hre.network.config.chainId
      let implementationContractAddress =  await artContract.getImplementationAddress()


      console.log({implementationContractAddress})

      if(!chainId){
        throw new Error("ChainId undefined")
      }

      let projectId = 0;
      let nonce = generateRandomNonce();
      let signatureResponse = generateArtSignature( artist, {projectId,nonce}, chainId, implementationContractAddress)
      
      
      if(!signatureResponse.data){
        console.log(signatureResponse)
        throw new Error("Signature failure")
      }
      
      
      let signature = signatureResponse.data.signature

      if(!signature){
        throw new Error("Signature undefined")
      } 


      let typeHash = await artContract.getTypeHash(projectId,nonce);
      console.log({typeHash})


      let domainSeparator = await artContract['DOMAIN_SEPARATOR']();
      console.log({domainSeparator})


      let mint = await artContract.connect(minter).mintToken(
        projectId,
        nonce,
        signature
      )

      let tokenId = 0; 

      let mintedTokenURI = await artContract.tokenURI( tokenId )

      expect(mintedTokenURI).to.eql('ipfs://')
 
    })

    it('should mint a token', async () => { 

      let chainId = hre.network.config.chainId
      let implementationContractAddress =  await artContract.getImplementationAddress()


      console.log({implementationContractAddress})

      if(!chainId){
        throw new Error("ChainId undefined")
      }

      let projectId = 0;
      let nonce = generateRandomNonce();
      let signatureResponse = generateArtSignature( artist, {projectId,nonce}, chainId, implementationContractAddress)

      if(!signatureResponse.data){
        console.log(signatureResponse)
        throw new Error("Signature failure")
      }
      
      let signature = signatureResponse.data.signature
      let secretMessage = signatureResponse.data.secretMessage
      
      if(!signature){
        throw new Error("Signature undefined")
      }


      let typeHash = await artContract.getTypeHash(projectId,nonce);
      console.log({typeHash})


      let domainSeparator = await artContract['DOMAIN_SEPARATOR']();
      console.log({domainSeparator})

    

      let mint = await artContract.connect(minter).mintTokenFromSecretMessage(
       secretMessage
      )


      let tokenId = 1; 

      let mintedTokenURI = await artContract.tokenURI( tokenId )

      expect(mintedTokenURI).to.eql('ipfs://')



    })
  
})
