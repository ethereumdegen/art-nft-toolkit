import { Wallet } from "ethers";
import { generateArtSignature, generateRandomNonce } from "../lib/art-signature-tools";

require('dotenv').config()
const ARTIST_PRIVATE_KEY = process.env.ARTIST_PRIVATE_KEY
 
if(!ARTIST_PRIVATE_KEY) throw new Error('Missing ARTIST_PRIVATE_KEY')

export type GenerateSignaturesInput = {

    artistPrivateKey: string,
    projectId: number,    
    chainId:number,
    implementationContractAddress:string,
    quantity: number,
    startNonce: number 

} 


const generationConfig:GenerateSignaturesInput = {

    artistPrivateKey: ARTIST_PRIVATE_KEY,
    projectId: 0, 
    chainId: 5,
    implementationContractAddress: "0x50D75C1BC6a1cE35002C9f92D0AF4B3684aa6B74",
    quantity: 10,
    startNonce: 0 

}




export function generateSignatures(args:string[]){

 
    let results =  generateSignaturesFromData(generationConfig);

    console.log(results)

    return results 
}


 export function generateSignaturesFromData(
    input : GenerateSignaturesInput
     ) : any[] {


    let outputs:any[] = [] 


    for(let i=0;i<input.quantity;i++){

        let projectId = input.projectId
        let nonce = input.startNonce + i ;

        let implementationContractAddress = input.implementationContractAddress
        let chainId = input.chainId

        let artistWallet = new Wallet(input.artistPrivateKey)

        let signatureResponse = generateArtSignature( artistWallet, {projectId,nonce}, chainId, implementationContractAddress)

        if(signatureResponse.data){
                outputs.push(
                    signatureResponse.data
                )
        }else{
            console.error("Unable to generate signature!!", signatureResponse)
        }
 
    }

    return outputs
 }