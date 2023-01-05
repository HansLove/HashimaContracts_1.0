// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

// Interfaz para implementar sistema de firma en un NFT
abstract contract ERCSign is Ownable{

    mapping(uint256=>bool)private SIGNED;

    function sign(uint256 hashimaID)external onlyOwner{
        require(!SIGNED[hashimaID],'Already signed');
        SIGNED[hashimaID]=true;
    }

    function isSigned(uint256 hashimaID)external view returns(bool){
        return SIGNED[hashimaID];
    }
}
