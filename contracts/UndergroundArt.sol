

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


// Libraries
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";


/*

This contract should be deployed as a proxy 

*/

contract UndergroundArt is ERC721Upgradeable, OwnableUpgradeable {

    //each nft tokenid will be  [this constant * artProjectId + tokenId]
    uint256 immutable MAX_PROJECT_QUANTITY = 10000;

    bytes32 public immutable DOMAIN_SEPARATOR;

    string public contractName;
    string public contractVersion; //used for offchain signature domain separator



    struct ArtProject {
        address artistAddress;
        string metadataURI;
        uint256 totalSupply;  //must be less than or equal to MAX_PROJECT_QUANTITY   
        uint256 mintedCount;
    }   

    event DefinedProject(uint256 indexed projectId, address artistAddress, uint256 totalSupply);

    uint256 projectCount;

    // projectId => ArtProject
    mapping(uint256 => ArtProject) public artProjects;
    mapping(bytes32 => bool) public usedSignatureHashes;


    //see how artblocks uses name and sym
     constructor () public
        ERC721Upgradeable()
    {
    
        DOMAIN_SEPARATOR = makeDomainSeparator(contractName, contractVersion);


    }


    function initialize() public initializer {

        contractName = "UndergroundArt";
        contractVersion = "1.0";

        __Ownable_init();
        
        __ERC721_init(contractName,"UA");

    }


    /**
     * @notice Creates the domain separator for EIP712 signature verification.
     * @param name The formal name for this contract.
     * @param version The current version of this contract.
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }




    function defineProject (
        address _artistAddress,      
        string memory _metadataURI,
        uint256 _totalSupply
    )  public onlyOwner {

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
        uint256 projectId,
        string memory _metadataURI
    ) public onlyOwner {
        artProjects[projectCount].metadataURI = _metadataURI;
    }


    /*
     A 'secret message' is a _project id and _nonce concatenated to a _secretCode and this is what we can give to people. our method will decode 

    */


    function mintTokenFromSecretMessage( 
        bytes calldata _secretMessage
    ) public
    {   
        uint256 _projectId;
        uint256 _nonce;
        bytes memory _signature; //secret code 
        (_projectId, _nonce, _signature) = abi.decode(_secretMessage, (uint256, uint256, bytes));
        mintTokenTo(msg.sender,_projectId,_nonce,_signature);
    }


    function mintToken(
        uint256 _projectId,
        uint256 _nonce,
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
        uint256 _projectId,
        uint256 _nonce,
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
        uint256 projectId,
        uint256 nonce,
        bytes memory signature
    ) internal view returns (bool) {

        bytes32 typeHash = keccak256( 
                                abi.encode( keccak256(
                                    "inputs(uint256 projectId, uint256 nonce)"
                                ), 
                                projectId, 
                                nonce ) );

        bytes32 dataHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, typeHash)
        );

        return ECDSAUpgradeable.recover(  
            dataHash, signature
        ) == signerAddress;
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