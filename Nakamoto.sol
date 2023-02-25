// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./Private.sol";
import "./Market.sol";

/**@dev
version:v1
Nakamoto Smart Contract:first implementation of Hashima protocol.
by: Aaron Tolentino */

contract Nakamoto is Market{
// Private,

    uint256 HARD_CAP=21000;
    
    
    constructor() ERC721("Nakamoto", "NAKAMOTOS") {}

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
        uint256 _stars,
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

    // mint a Hashima in behalf of other user
    function mintFor(
        uint256 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver)public 
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
        
            return _id;

    }

}