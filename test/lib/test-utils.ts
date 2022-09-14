import { Provider } from '@ethersproject/abstract-provider'
import { Wallet } from 'ethers'
import hre, { ethers } from 'hardhat'
import { getFunds } from '../../helpers/get-funds'

export async function createAndFundRandomWallet(provider: any): Promise<Wallet> {
 

  const wallet = Wallet.createRandom().connect(provider)

  await getFunds({
    to: await wallet.getAddress(),
    tokenSym: 'ETH',
    amount: hre.ethers.utils.parseEther('1000'),
    hre,
  })

  return wallet
}


export function getNetworkNameFromChainId(chainId: number): string {
  if (chainId == 4) return 'rinkeby'
  if (chainId == 5) return 'goerli'
  if (chainId == 137) return 'polygon'

  return 'mainnet'
}
