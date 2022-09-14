 
import chai, { expect } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { BigNumber, Contract,   Signer, Wallet } from 'ethers'
import hre, { ethers } from 'hardhat'
//import { deploy } from 'helpers/deploy-helpers'
import { UndergroundArt } from '../generated/typechain'
import { deploy } from '../helpers/deploy-helpers'
import { createAndFundRandomWallet } from './test-utils' 


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

 
  let artist: Wallet 
  let minter: Wallet  

  before(async () => {


    artist = await createAndFundRandomWallet( ethers.provider )
    minter = await createAndFundRandomWallet( ethers.provider )

    //let minerEth = await miner.getBalance()

   
    const result = await setup()
    artContract = result.artContract


     })


  

    it('should deposit and withdraw', async () => { 

 
       
  

  })
 

     
  
})
