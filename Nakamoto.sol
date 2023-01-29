// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Private.sol";
import "./Market.sol";

/**@dev
version:v1
Nakamoto Smart Contract:first implementation of Hashima protocol.
by: Aaron Tolentino */
contract Nakamoto is Private,Market{

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
    function Mint(
        uint256 _stars,
        string memory _data,
        string memory _nonce,
        string memory _uri,
        uint256 _price,
        bool _forSale
        )public checkMintingData(_data,_stars,_price)returns(uint256){
        
        uint256 _id=0;
        require(HARD_CAP>getTotal(),'hard cap reached');

        _id=createHashimaItem(
            _data,
            _nonce,
            _stars,
            _uri,
            _price,
            _forSale,
            msg.sender
            );
        return _id;
        
    }    

    //mint a Hashima in behalf of other user
    function MintFor(
        uint256 _stars,
        string memory _data,
        string memory _nonce,
        string memory _uri,
        uint256 _price,
        bool _forSale,
        address _receiver)public checkMintingData(_data,_stars,_price)returns(uint256){
            uint256 _id=0;
            require(HARD_CAP>getTotal(),'hard cap reached');
    
            _id=createHashimaItem(
                _data,
                _nonce,
                _stars,
                _uri,
                _price,
                _forSale,
                _receiver
                );
        
            return _id;

    }

}