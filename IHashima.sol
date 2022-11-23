// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';


interface IHashima is IERC721{

    struct Hashi {
      uint256 tokenId;
      string data;
      address payable currentOwner;
      address payable previousOwner;
      uint256 stars;
      uint256 blockTolerance;
      string nonce;
      uint256 price;
      bool forSale;
    }
  
    //Events
    event GameStart(uint256 _blocknumber);

    event Minted(bool respuesta,bytes32 hashResultado,uint256 id);

    //Get all the data save in the blockchain. 
    //You can get the proof of work variables to 'check' the Hashima power
    function get(uint256 _index)external view returns(Hashi memory);

    function getTotal()external view returns(uint256);
    
    function checkTolerance()external view returns(uint256);

    function buyToken(uint256 _tokenId)external payable returns(bool);

    /**
    Called by the user to set a initial 'Tolerance' Number.
     */
    function Init()external returns(uint256);

    function Mint(
      uint256 _stars,
      string memory _data,
      string memory _nonce,
      string memory _uri,
      uint256 _price,
      bool _forSale
      )external;


    function toggleForSale(uint256 _tokenId,uint256 _price) external;

    //This function change the price and the sale state in the same transaction
    // function toggleForSaleAndPrice(uint256 _tokenId, uint256 _newPrice)external;
    //Only changes the price
    function changePrice(uint256 _tokenId,uint256 _newPrice) external;

}