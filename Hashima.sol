// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Hashima.sol";


contract Hashima is ERC721Hashima,Ownable{

    mapping(uint256=>bool)private SIGNED;
   
    constructor() ERC721("Hashima", "HASHIMA") {}

    function MintFor(
        uint256 _stars,
        string memory _data,
        string memory _nonce,
        string memory _uri,
        uint256 _price,
        bool _forSale,
        address _receiver)public checkMintingData(_data,_stars,_price){
            uint256 _id=0;

            (bool respuesta,bytes32 _hashFinal)
            =proofOfWork(_data,_nonce,_stars);
      
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
            
            emit Minted(respuesta,_hashFinal,_id);
    }

    function signHashima(uint256 hashimaID)external onlyOwner{
        require(!SIGNED[hashimaID],'Already signed');
        SIGNED[hashimaID]=true;
    }

    function isSigned(uint256 hashimaID)external view returns(bool){
        return SIGNED[hashimaID];
    }
}