// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DNA.sol";
import "./Market.sol";


contract Hashimon is DNA,Market{
   
    constructor() ERC721("Hashimon", "HASHIMON") {}

    function MintFor(
        uint256 _stars,
        string memory _data,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
        )public checkMintingData(_data,_stars,_price) returns(uint256){
            uint256 _id=0;

            (bool respuesta,)=proofOfWork(_data,_nonce,_stars);
      
            if (respuesta) {
                //Convert '_data' string in true inside the mapping.   
                _names[_data]=true; 

                _id=createHashimaItem(
                    _data,
                    _nonce,
                    _stars,
                    _price,
                    _forSale,
                    _receiver
                    );
            }
            
            return _id;
    }

    function Mint(
        uint256 _stars,
        string memory _data,
        string memory _nonce,
        uint256 _price,
        bool _forSale
        )public checkMintingData(_data,_stars,_price){

        uint256 _id=0;

        (
            bool respuesta,
            bytes32 _hashFinal)=proofOfWork(_data,_nonce,_stars);
        
        if (respuesta) {
            _names[_data]=true; 

            _id=createHashimaItem(
                _data,
                _nonce,
                _stars,
                _price,
                _forSale,
                msg.sender
                );
        }
        
        emit Minted(respuesta,_hashFinal,_id);
    }    

}