
 
import fs from 'fs'
import path from 'path'


import web3utils from 'web3-utils'

 
export default class FileHelper{


    static  readJSONFile(uri:string){

         let input =  fs.readFileSync(path.resolve( uri),   {encoding:'utf8', flag:'r'}); 

         return JSON.parse(input)
    }

    static readLocalFile( path:string, encoding: BufferEncoding){

        return fs.readFileSync(path,{ encoding  });
     
    }

    static readLocalFileUTF8( path:string  ){

        let output = fs.readFileSync(path,{ encoding: 'utf8' });
    
        return output 

    }


    static mkdirSync(path:string){
        try{
            fs.mkdirSync(path)
        }catch(e){
            //console.error(e)
        }
       
    }
    
    static saveUTF8FileToCache(data: string, filePath: string) : {savedFile: boolean, error:any} {
     

        try{
            fs.writeFileSync(
                path.join( filePath) , 
                data, 'utf8')
            return {savedFile: true , error:undefined}
        }catch(error){
            console.error(error)
            return {savedFile: false , error:error}
        } 

    }

 
 

    static addRandomSaltToFileName(fileName:string){

        let fileNameSalt = web3utils.randomHex(16)

        let fileNamePrefix = fileName.split('.')[0]
        let fileNamePostfix = fileName.split('.')[1]

        return fileNamePrefix.concat('_').concat(fileNameSalt).concat('.').concat(fileNamePostfix)

    }


}