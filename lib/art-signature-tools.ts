 
import {
    bufferToHex,
    ecrecover,
    ecsign,
    pubToAddress,
    toBuffer,
    toRpcSig,
  } from 'ethereumjs-util'
  import { BigNumber, utils, Wallet } from 'ethers'
 
const crypto = require('crypto')

const contractName = "DetroitLocalArt"
const contractVersion = "1.0"

export type SignatureInputs = {projectId:Uint8Array, nonce:number}
 

export interface DomainData {
    name: string
    version: string
    chainId: number
    verifyingContract: string
  }
  

function getDomainData(chainId: number, verifyingContractAddress:string): DomainData {
  
    const abiCoder = new utils.AbiCoder()
  
    const domainString = utils.keccak256(
      utils.toUtf8Bytes(
        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
      )
    )
  
    const domainData: DomainData = {
      name: contractName,
      version: contractVersion,
      chainId,
      verifyingContract: verifyingContractAddress,
    }
  
    const domainSeparator = utils.keccak256(
      abiCoder.encode(
        ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
        [
          domainString,
          utils.keccak256(utils.toUtf8Bytes(domainData.name)),
          utils.keccak256(utils.toUtf8Bytes(domainData.version)),
          domainData.chainId,
          domainData.verifyingContract,
        ]
      )
    )
 
  
    const TypedDataEncoder = utils._TypedDataEncoder
  
    const hashDomain = TypedDataEncoder.hashDomain(domainData)
  
    if (hashDomain != domainSeparator) {
      throw new Error('domainhash mismatch')
    }
  
    return domainData
  }

export function generateArtSignature(wallet:Wallet, projectId:string, nonce:number, chainId: number, contractAddress:string) : {success:boolean,data?: {secretMessage:string, signature:string, projectId: string, nonce: number}  ,error?:string} {

    const domainData = getDomainData(chainId, contractAddress)

    const types = {
        inputs: [
          { name: 'projectId', type: 'bytes32' },
          { name: 'nonce', type: 'uint16' },       
        ],
      }

    const values:SignatureInputs = {
      projectId:utils.arrayify(projectId),
      nonce
    }

    const TypedDataEncoder = utils._TypedDataEncoder

    const codedMessage = TypedDataEncoder.encode(domainData, types, values)
  
    const digest = utils.keccak256(codedMessage)
  
    const codedHash = TypedDataEncoder.hash(domainData, types, values)
  
    const hashStruct = TypedDataEncoder.hashStruct('inputs', types, values)
      
   // console.log({hashStruct})
 

    const msgBuffer = toBuffer(digest)

    const sig = ecsign(msgBuffer, toBuffer(wallet.privateKey))
  
    const pubKey = ecrecover(msgBuffer, sig.v, sig.r, sig.s)
    const addrBuf = pubToAddress(pubKey)
    const recoveredSignatureSigner = bufferToHex(addrBuf)
  
    if (recoveredSignatureSigner.toLowerCase() != wallet.address.toLowerCase()) {
      console.error(
        'recovered sig mismatched ',
        recoveredSignatureSigner,
        wallet.address
      )
      return { success: false, error: 'Signature mismatch.' }
    }
  
    const signature = toRpcSig(sig.v, sig.r, sig.s)

    console.log({signature})
    const secretMessage = utils.solidityPack(
        ['bytes32','uint16','bytes'],
        [
           utils.arrayify(projectId),
            nonce,
            signature
        ]
      )

  
    
    //const final_list: CraResponse = Object.assign({}, signature, input);
    return { success: true, data: 
        {

        projectId:projectId,
        nonce:nonce,
        signature,
        secretMessage
      }
    } 
}

export function generateRandomNonce() : number {


    return Math.floor(Math.random()*65535)

}


export function generateRandomProjectSeed() : string {

  return '0x'.concat(  crypto.randomBytes(32).toString('hex') )
}

export function calculateProjectIdHash(artistAddress:string, totalSupply:number, projectSeed:string) : string {


  const abiCoder = new utils.AbiCoder()

  return utils.keccak256(abiCoder.encode( ['address','uint16','bytes32'] , [artistAddress,totalSupply,utils.arrayify(projectSeed)]      ))

}
