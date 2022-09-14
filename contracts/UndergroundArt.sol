
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./BytesLib.sol";
// Libraries
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
 
/*

This contract should be deployed as a proxy 

 

*/



contract UndergroundArt is ERC721Upgradeable, OwnableUpgradeable {

    //each nft tokenid will be  [this constant * artProjectId + tokenId]
    uint16 immutable MAX_PROJECT_QUANTITY = 10000;

   

    struct ArtProject {
        address artistAddress;
        string metadataURI;
        uint16 totalSupply;  //must be less than or equal to MAX_PROJECT_QUANTITY   
        uint16 mintedCount;
    }   

    event DefinedProject(uint16 indexed projectId, address artistAddress, uint16 totalSupply);
    event AllowlistedArtist(address indexed artist, bool enabled);
   
    // projectId => ArtProject
    mapping(uint16 => ArtProject) public artProjects;
    mapping(bytes32 => bool) public usedSignatureHashes;

 
    uint16 projectCount;

    mapping(address => bool) public allowlistedArtists;




    modifier onlyOwnerOrSpecificArtist(address artist){
         require(_msgSender() == owner() || (  allowlistedArtists[_msgSender()] && _msgSender() == artist) , "Ownable: caller is not the owner");
        _;
    }

 
    //see how artblocks uses name and sym
     constructor () public
        ERC721Upgradeable()
    {
         
      
    }


    function initialize() public initializer {

        __Ownable_init();
        
        __ERC721_init("UndergroundArt","UA");

    }

 

    function getDomainSeparator()
     internal
        view
        returns (bytes32){
               uint256 chainId;
                assembly {
                    chainId := chainid()
                }
 

        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes("UndergroundArt")),
                    keccak256(bytes("1.0")),
                    chainId,
                    address(this) //proxy contract
                )
            );

        }

   


    function defineProject (
        address _artistAddress,      
        string memory _metadataURI,
        uint16 _totalSupply
    )  public onlyOwnerOrSpecificArtist(_artistAddress) {

        artProjects[projectCount] = ArtProject({
            artistAddress: _artistAddress,
            metadataURI: _metadataURI,
            totalSupply: _totalSupply,
            mintedCount : 0
        });

        emit DefinedProject(projectCount, _artistAddress, _totalSupply);

        projectCount +=1;

    }

    function modifyProjectMetadata(
        uint16 projectId,
        string memory _metadataURI
    ) public onlyOwnerOrSpecificArtist(artProjects[projectId].artistAddress) {
        artProjects[projectId].metadataURI = _metadataURI;
    }

    function setArtistAllowlist(address artistAddress, bool enabled)
    public onlyOwner
    {
        allowlistedArtists[artistAddress] = enabled;

        emit AllowlistedArtist(artistAddress, enabled);
    }


    /*
     A 'secret message' is a _project id and _nonce concatenated to a _secretCode and this is what we can give to people. our method will decode 

    */

    function mintTokenFromSecretMessage( 
        bytes memory _secretMessage
    ) public
    {

        require (_secretMessage.length == 69);

        uint16 _projectId;
        uint16 _nonce;
    
        bytes memory _signature; //secret code 
      

        assembly {
        _projectId := mload(add(_secretMessage, 0x02))
        _nonce := mload(add(_secretMessage, 0x04))           
        }

        _signature = BytesLib.slice( _secretMessage, 4, 65 );
          
      
        mintTokenTo(msg.sender,_projectId,_nonce,_signature);
    }


    function mintToken(
        uint16 _projectId,
        uint16 _nonce,
        bytes memory _signature
    ) public
    {   
       mintTokenTo(msg.sender,_projectId,_nonce,_signature);
    }


   /**
    * Custom accessor to create a unique token
    */
    function mintTokenTo(
        address _to,
        uint16 _projectId,
        uint16 _nonce,
        bytes memory _signature
    ) public
    {   
        uint256 _tokenId = (_projectId * MAX_PROJECT_QUANTITY) + artProjects[_projectId].mintedCount;

        artProjects[_projectId].mintedCount += 1;

        require(artProjects[_projectId].mintedCount <= artProjects[_projectId].totalSupply, "Total supply has been minted for this project.");

        require(signatureHasBeenUsed(_signature)==false,"Code already used");
        usedSignatureHashes[keccak256(_signature)] = true;

        //make sure secret code ECrecovery of hash(projectId, nonce) == artist admin address  
        require(_validateSecretCode( artProjects[_projectId].artistAddress, _projectId, _nonce, _signature ), "Signature invalid");


        
        super._safeMint(_to, _tokenId);
       
    }

    function signatureHasBeenUsed(
        bytes memory _signature
    ) public view returns (bool){
        return usedSignatureHashes[keccak256(_signature)];
    }

    function _validateSecretCode(
        address signerAddress,
        uint16 projectId,
        uint16 nonce,
        bytes memory signature
    ) internal view returns (bool) {

        bytes32 typeHash = getTypeHash(projectId,nonce);

        bytes32 dataHash = keccak256(
            abi.encodePacked("\x19\x01", getDomainSeparator(), typeHash)
        );

        return ECDSAUpgradeable.recover(  
            dataHash, signature
        ) == signerAddress;
    }


    function getTypeHash(uint16 projectId, uint16 nonce) public view returns (bytes32){
        return keccak256( abi.encode( keccak256(
                        "inputs(uint16 projectId,uint16 nonce)"
                        ), 
                        projectId, 
                        nonce ) );
    }

     /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId));

        uint16 projectId = getProjectIdFromTokenId(tokenId);

        return artProjects[projectId].metadataURI;
    }



  
    function getProjectIdFromTokenId(uint256 tokenId) public view returns (uint16){
          //test me thoroughly !
          return uint16(tokenId/MAX_PROJECT_QUANTITY);
    }



}