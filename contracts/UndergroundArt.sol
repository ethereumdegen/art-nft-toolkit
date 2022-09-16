
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
        address signerAddress;
        address payoutAddress;
        string metadataURI;
        uint16 totalSupply;  //must be less than or equal to MAX_PROJECT_QUANTITY   
        uint16 mintedCount;
        uint256 mintPrice;
        bool reuseableCodes;
    }   

    event DefinedProject(uint16 indexed projectId, address signerAddress, address payoutAddress, uint16 totalSupply, uint256 mintPrice, bool reuseableCodes);
    event UpdatedMintPrice(uint16 indexed projectId, uint256 mintPrice);
    event UpdatedMetadataURI(uint16 indexed projectId);
    event UpdatedReuseableCodes(uint16 indexed projectId, bool reuseableCodes);
    event UpdatedPayoutAddress(uint16 indexed projectId, address payoutAddress);

    event AllowlistedArtist(address indexed artist, bool enabled);
    
    event MintToken(address to, uint256 tokenId, uint16 nonceUsed);


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
        address _signerAddress,  
        address _payoutAddress,    
        string memory _metadataURI,
        uint16 _totalSupply,
        uint256 _mintPrice
    )  public onlyOwnerOrSpecificArtist(_signerAddress) {

        artProjects[projectCount] = ArtProject({
            signerAddress: _signerAddress,
            payoutAddress: _payoutAddress,
            metadataURI: _metadataURI,
            totalSupply: _totalSupply,
            mintedCount : 0,
            mintPrice: _mintPrice,
            reuseableCodes:false
        });

        emit DefinedProject(projectCount, _signerAddress,_payoutAddress, _totalSupply, _mintPrice, false);

        projectCount +=1;

    }

    function modifyProjectMetadata(
        uint16 _projectId,
        string memory _metadataURI
    ) public onlyOwnerOrSpecificArtist(artProjects[_projectId].signerAddress) {
        artProjects[_projectId].metadataURI = _metadataURI;
    
        emit UpdatedMetadataURI(_projectId);
    
    }

    function modifyProjectMintPrice(
        uint16 _projectId,
        uint256 _mintPrice
    ) public onlyOwnerOrSpecificArtist(artProjects[_projectId].signerAddress) {
        artProjects[_projectId].mintPrice = _mintPrice;

        emit UpdatedMintPrice(_projectId, _mintPrice);
    
    }

     function modifyProjectPayoutAddress(
        uint16 _projectId,
        address _payoutAddress
    ) public onlyOwnerOrSpecificArtist(artProjects[_projectId].signerAddress) {
        artProjects[_projectId].payoutAddress = _payoutAddress;

        emit UpdatedPayoutAddress(_projectId, _payoutAddress);
    
    }

    function modifyProjectReuseableCodes(
        uint16 _projectId,
        bool _reuseableCodes
    ) public onlyOwnerOrSpecificArtist(artProjects[_projectId].signerAddress) {
        artProjects[_projectId].reuseableCodes = _reuseableCodes;
    
        emit UpdatedReuseableCodes(_projectId,_reuseableCodes);
    
    }


    function setArtistAllowlisted(address artistAddress, bool enabled)
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
    ) public payable
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
          
      
        _mintTokenTo(msg.sender,_projectId,_nonce,_signature);
    }


    function mintToken(
        uint16 _projectId,
        uint16 _nonce,
        bytes memory _signature
    ) public payable
    {   
       _mintTokenTo(msg.sender,_projectId,_nonce,_signature);
    }


 
    function _mintTokenTo(
        address _to,
        uint16 _projectId,
        uint16 _nonce,
        bytes memory _signature
    ) internal 
    {   
        uint256 _tokenId = (_projectId * MAX_PROJECT_QUANTITY) + artProjects[_projectId].mintedCount;

        artProjects[_projectId].mintedCount += 1;

        require(artProjects[_projectId].mintedCount <= artProjects[_projectId].totalSupply, "Total supply has been minted for this project.");

        require(signatureHasBeenUsed(_signature)==false && !artProjects[_projectId].reuseableCodes,"Code already used");
        usedSignatureHashes[keccak256(_signature)] = true;

        //make sure secret code ECrecovery of hash(projectId, nonce) == artist admin address  
        require(_validateSecretCode( artProjects[_projectId].signerAddress, _projectId, _nonce, _signature ), "Signature invalid");
        
       
        super._safeMint(_to, _tokenId);

        //forward the eth to the artist account
        //perform this call at the end to mitigate re-entrancy exploits 
        require(msg.value == artProjects[_projectId].mintPrice, "Invalid payment for mint");
        payable(artProjects[_projectId].payoutAddress).transfer(msg.value); //send funds to artist
        
        emit MintToken(_to, _tokenId, _nonce);
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