// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;    


import "./Market.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**@dev
version:v1
Nakamoto Smart Contract:first implementation of Hashima protocol.
by: Aaron Tolentino */
contract Nakamoto is Market{

    uint256 immutable HARD_CAP=21000;
    
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("Nakamoto", "NAKAMOTOS") {}
      
    event Minted(uint256);
    /* 
    @param: stars: amount of 0's in hash(PoW) 
    @param: _data: unique string for PoW
    @param: _nonce: unique number for PoW
    @param: _uri: location metadata
    @param: price: starting price
    @param: forSale: is availiable
    1.checkMintingData inside ERC721Hashima.sol
    2.check proof of work */
    function mint(
        uint8 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale
        )public 
        override 
        returns(uint256){
        // ID Hashima NFT
        uint256 _id=0;
        // Check supply limit Nakamoto collection
        require(HARD_CAP>getTotal(),'hard cap reached');

        _id=register(
            msg.sender,
            _stars,
            _nonce,
            _price,
            _forSale);

        _tokenURIs[_id] = _uri;

        emit Minted(_id);
        
        return _id;
        
    }    

    // mint a Hashima in behalf of other user
    function mintFor(
        uint8 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
        )public 
        override 
        returns(uint256){

            uint256 _id=0;

            require(HARD_CAP>getTotal(),'hard cap reached');
    
            _id=register(
                _receiver,
                _stars,
                _nonce,
                _price,
                _forSale
                );
        
            _tokenURIs[_id] = _uri;
            
            emit Minted(_id);

            return _id;

    }

    // Define metadata provider of the Hashima
    function setTokenURI(uint256 tokenId,string memory _uri) public{
        require(_exists(tokenId), "URI query for nonexistent token");
        require(ownerOf(tokenId)==msg.sender);
        _tokenURIs[tokenId] = _uri;


    }
    // Metadata of the Hashima
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;

    }
}
