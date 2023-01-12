// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Private.sol";
import "./Market.sol";

/**@dev
version:v1
Nakamoto Smart Contract:first implementation of Hashima protocol.
by: Aaron Tolentino */
contract Nakamoto is Private,Market{
   
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
        )public checkMintingData(_data,_stars,_price){

        uint256 _id=0;

        (bool respuesta,bytes32 _hashFinal)=proofOfWork(_data,_nonce,_stars);
        
        if (respuesta) {
            //Convert '_data' string in true inside the mapping.   
            _names[_data]=true; 

            _id=createHashimaItem(
                _data,
                _nonce,
                _stars,
                _uri,
                _price,
                _forSale,
                msg.sender
                );
        }
        
        emit Minted(respuesta,_hashFinal,_id);
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

            (bool respuesta,)=proofOfWork(_data,_nonce,_stars);
      
            if (respuesta) {
                //Convert '_data' string in true inside the mapping.   
                _names[_data]=true; 

                _id=createHashimaItem(
                    _data,
                    _nonce,
                    _stars,
                    _uri,
                    _price,
                    _forSale,
                    _receiver
                    );
            }
            
            return _id;

    }

}