// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ERC721Hashima.sol";


contract NoHashima is ERC721Hashima{

    constructor() ERC721("NotHashima", "NOTHASHIMA") {}



}