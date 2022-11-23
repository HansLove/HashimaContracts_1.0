// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHashima.sol";


contract AntiBot is ERC721,Ownable{

    // mapping(uint256=>bool)private SIGNED;

    using Counters for Counters.Counter;

   
   IHashima private BASE_CONTRACT;

    Counters.Counter internal _tokenIds;


    constructor(IHashima _hashima) ERC721("AntiBot", "ANTIBOT") {
        BASE_CONTRACT=_hashima;
    }

    struct Vote{
        uint256 blockHeight;
    }

    mapping(uint256=>Vote) VOTES ;

    // function signHashima(uint256 hashimaID)external onlyOwner{
    //     require(!SIGNED[hashimaID],'Already signed');
    //     SIGNED[hashimaID]=true;
    // }

    // function isSigned(uint256 hashimaID)external view returns(bool){
    //     return SIGNED[hashimaID];
    // }


    function lockHashima(uint256 hashimaID,uint256 amountOfBlocks)external{
        BASE_CONTRACT.get(hashimaID);
        BASE_CONTRACT.safeTransferFrom(msg.sender, address(this), hashimaID);
        Vote memory vote=Vote(
            amountOfBlocks
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);

        VOTES[newItemId]=vote;
     
    }

    
}