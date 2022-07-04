// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Hashima.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';


contract DutchAuction{
    uint256 private DURATION=5000;

    struct Auction{
        uint256 started;
        uint256 expire;
    }

    constructor(){

    }

    uint price;
    uint public discountRate;
    mapping(uint256=>Auction)public records;

    function getPrice(uint256 hashima_id)public view returns(uint){
        uint256 startedAt=records[hashima_id].started;
        uint256 timeElapsed=block.number-startedAt;
        uint discount=discountRate*timeElapsed;
        return price-discount;
    }

    function buy(uint256 hashima_id)external payable{
        uint256 expireBlock=records[hashima_id].expire;

        require(block.number<expireBlock,'no yet');
    }
}
  