// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;    
import "@openzeppelin/contracts/utils/Strings.sol";


contract Calculator{

using Strings for uint256;



function checkHash(
        string memory _data,
        string memory _nonce,
        uint256 _tolerance,
        uint256 _stars)public pure returns(bool,bytes32){
    
        bytes32 _hashFinal=sha256(abi.encodePacked(
        _data,
        _nonce
        ,Strings.toString(_tolerance)
        ));

        bool respuesta=true;


        for (uint256 index = 0; index < _stars; index++) {
            if (_hashFinal[index]!=0x00) {
                    respuesta=false;  
                }
        
        }

        return (respuesta,_hashFinal);
        
    }

}