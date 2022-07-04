// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Hashima.sol";


contract Hashima is ERC721Hashima{
   
    constructor() ERC721("Hashima", "HASHIMA") {}


        
}