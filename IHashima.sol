// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';



interface IHashima is IERC721{


    // function Init()external;

    function Mint(uint256 _stars,string memory _data,string memory _nonce,
    string memory _uri,
    uint256 _price,
    bool _forSale)external;

    // function getBlockTolerance()external returns(uint256);

    // function getStars(uint256 tokenID)external returns(uint256);

    // function getProofOfWorkData(uint256 tokenID)external view returns(string memory,uint256,string memory,uint256,uint256);


    // function checkingHash(string memory _data,string memory _nonce,
    // uint256 _tolerance,
    // uint256 _stars)external pure returns(bool,bytes32);

}