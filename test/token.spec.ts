 
import chai, { expect } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { BigNumber, Contract,   Signer, Wallet } from 'ethers'
import hre, { ethers } from 'hardhat'
//import { deploy } from 'helpers/deploy-helpers'
import { XBitcoinTokenTest, XBitsToken } from '../generated/typechain'
import { getPayspecInvoiceUUID, PayspecInvoice , ETH_ADDRESS} from 'payspec-js'
import { deploy } from '../helpers/deploy-helpers'
import { createAndFundRandomWallet } from './test-utils'
import { ApprovalInputs, DomainData, signPermitApproval } from './lib/EIP2616SDK'

chai.should()
chai.use(chaiAsPromised)

const {   deployments } = hre

// eslint-disable-next-line @typescript-eslint/no-empty-interface
interface SetupOptions {}

interface SetupReturn {
  originalTokenContract: XBitcoinTokenTest
  upgradeTokenContract: XBitsToken
}

const setup = deployments.createFixture<SetupReturn, SetupOptions>(
  async (hre, _opts) => {
   
   
    await hre.deployments.fixture(['primary'], {
      keepExistingDeployments: false,
    })

    const originalTokenContract = await hre.contracts
    .get<XBitcoinTokenTest>('_0xBitcoinTokenTest')
    const upgradeTokenContract = await hre.contracts
    .get<XBitsToken>('xBitsToken')
   
        
      

    return {
      originalTokenContract,
      upgradeTokenContract
    }
  }
)



describe('Upgrade Contract', () => {

  let originalTokenContract: XBitcoinTokenTest
  let upgradeTokenContract: XBitcoinTokenV2

 
  let miner: Wallet 
  let permitter: Wallet  

  before(async () => {


    miner = await createAndFundRandomWallet( ethers.provider )
    permitter = await createAndFundRandomWallet( ethers.provider )

    let minerEth = await miner.getBalance()

   
    const result = await setup()
    originalTokenContract = result.originalTokenContract
    upgradeTokenContract = result.upgradeTokenContract 
 

  })


  

    it('should deposit and withdraw', async () => { 

 
       
  

  })
 

     
  
})
