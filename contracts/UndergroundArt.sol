


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract UndergroundArt is ERC721 {

    //each nft tokenid will be  [this constant * artProjectId + tokenId]
    uint256 immutable MAX_PROJECT_QUANTITY = 10000;

    

    struct ArtProject {
        address artistAddress;
        address adminAccountAddress;
        string metadataURI;
        uint256 maxQuantity;  //must be less than or equal to MAX_PROJECT_QUANTITY   
        uint256 quantityMinted;
    }

    // projectId => ArtProject
    mapping(uint256 => ArtProject) public artProjects;


     constructor (string memory _name, string memory _symbol) public
        ERC721(_name, _symbol)
    {
        
    }

   /**
    * Custom accessor to create a unique token
    */
    function mintTokenTo(
        address _to,
        uint256 _projectId,
        uint256 _nonce,
        bytes32 _secretCode
    ) public
    {   

        //make sure secret code ECrecovery of hash(projectId, nonce) == artist admin address  
        super._mint(_to, _tokenId);
       
    }


     /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId));

        uint256 projectId = getProjectIdFromTokenId(tokenId);

        return artProjects[projectId].metadataURI;
    }



  
    function getProjectIdFromTokenId(uint256 tokenId) public view returns (uint){
          //test me thoroughly !
          return (tokenId/MAX_PROJECT_QUANTITY);
    }



}