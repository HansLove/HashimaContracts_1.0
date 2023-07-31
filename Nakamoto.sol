// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Market.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**@dev
version:v1
Nakamoto Smart Contract:first implementation of Hashima protocol.
by: Aaron Tolentino */

contract Nakamoto is Market,Ownable{

    uint256 immutable HARD_CAP=21000;
    
    string internal baseURI="https://hashima.xyz/";

    constructor() ERC721("Nakamoto", "NAKAMOTOS") {}
    /** 
    1.Check randomizer is not 0. 
    2.Tolerance plus BLOCK TOLERANCE has to be more than the current block
    3.The proof of work data has to be unique in this smart contract.
    4.Sender cannot be 0
    5.Number of stars cannot be 0
    6.Price at least 1 wei
    */
    modifier checkMintingData(string memory _uri,uint256 _stars,uint256 _price){
        require(randomizer[msg.sender]!=0,'not randomizer');
        require(timing[msg.sender]!=0,'not timing');
        require(timing[msg.sender]+600>block.timestamp,"Timing is expire");
        require(bytes(_uri).length >= 1, "Data must be at least 1 byte long");
        require(msg.sender != address(0));
        require(_price>0,"Price cannot be 0");
        _;
    }
      
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
        checkMintingData(_uri,_stars,_price)
        returns(uint256){
        // ID Hashima NFT
        uint256 _id=0;
        // Check supply limit Nakamoto collection
        require(HARD_CAP>getTotal(),'hard cap reached');

        _id=register(
            _uri,
            msg.sender,
            _stars,
            _nonce,
            _price,
            _forSale
            );
        return _id;
        
    }    

    event Minted(uint256);

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
        checkMintingData(_uri,_stars,_price)
        returns(uint256){

            uint256 _id=0;

            require(HARD_CAP>getTotal(),'hard cap reached');
    
            _id=register(
                _uri,
                _receiver,
                _stars,
                _nonce,
                _price,
                _forSale
                );
        
            emit Minted(_id);
            return _id;

    }

    // Metadatas
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "URI query for nonexistent token");
    //     return string(abi.encodePacked(baseURI,Strings.toString(tokenId),".json"));

    // }

    // // Ony owner can define a new API URL
    // function _setTokenURI(string memory new_uri)external onlyOwner{
    //     baseURI=new_uri;
    // } 

}