// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Hashima.sol";


contract Hashima is ERC721Hashima,Ownable{

    mapping(uint256=>bool)private SIGNED;
   
    constructor() ERC721("Hashima", "HASHIMA") {}

    function signHashima(uint256 hashimaID)external onlyOwner{
        require(!SIGNED[hashimaID],'Already signed');
        SIGNED[hashimaID]=true;
    }

    function isSigned(uint256 hashimaID)external view returns(bool){
        return SIGNED[hashimaID];
    }

    
}