


import { BigNumber, utils, Wallet } from 'ethers'
import { AbiCoder } from 'ethers/lib/utils'
 
 
 
 
const crypto = require('crypto')

export function generateRandomProjectSeed() : string {

    return '0x'.concat(  crypto.randomBytes(32).toString('hex') )
}

export function calculateProjectIdHash(artistAddress:string, totalSupply:number, projectSeed:string) : string {


    const abiCoder = new utils.AbiCoder()

    return utils.keccak256(abiCoder.encode( ['address','uint16','bytes32'] , [artistAddress,totalSupply,utils.arrayify(projectSeed)]      ))

}