import { Wallet } from "ethers";
import { generateArtSignature, generateRandomNonce } from "../lib/art-signature-tools";

require('dotenv').config()
const ARTIST_PRIVATE_KEY = process.env.ARTIST_PRIVATE_KEY
 
import FileHelper from '../lib/filehelper'

if(!ARTIST_PRIVATE_KEY) throw new Error('Missing ARTIST_PRIVATE_KEY')

export type GenerateSignaturesInput = {

    artistPrivateKey: string,
    projectId: number,    
    chainId:number,
    proxyContractAddress:string,
    quantity: number,
    startNonce: number 

} 


const generationConfig:GenerateSignaturesInput = {

    artistPrivateKey: ARTIST_PRIVATE_KEY,
    projectId: 3, 
    chainId: 5,
    proxyContractAddress: "0x3c0d23ffab351f69116029f63919061e1ae9c142",
    quantity: 10,
    startNonce: 0 

}




export function generateSignatures(args:string[]){

 
    let results =  generateSignaturesFromData(generationConfig);

    console.log(results)

    let outputPath = 'tasks/output/generatedsignatures.json'
    let saved = FileHelper.saveUTF8FileToCache(JSON.stringify(results), outputPath )

    return results 
}


 export function generateSignaturesFromData(
    input : GenerateSignaturesInput
     ) : any[] {


    let outputs:any[] = [] 


    for(let i=0;i<input.quantity;i++){

        let projectId = input.projectId
        let nonce = input.startNonce + i ;

        let address = input.proxyContractAddress
        let chainId = input.chainId

        let artistWallet = new Wallet(input.artistPrivateKey)

        let signatureResponse = generateArtSignature( artistWallet, {projectId,nonce}, chainId, address)

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