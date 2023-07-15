// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IHashima is IERC721 {

  struct Hashi {
    uint256 tokenId;//unique number for Hashima
    address payable currentOwner;
    address payable previousOwner;
    uint8 stars;
    uint256 blockTolerance;
    uint256 timing;
    string nonce;
    uint256 price;
    bool forSale;
  }

  event InitProtocol(uint256 _blocknumber, uint256 _timing);

  event Minted(bool answer, bytes32 hashResultado, uint256 id);

  // Start the Hashima protocol
  function init() external returns(uint256, uint256);    

  // Get one Hashima
  function get(uint256 _index) external view returns(Hashi memory);

  // Creates a Hashima
  function mint(
    uint8 _stars,
    string memory _uri,
    string memory _nonce,
    uint256 _price,
    bool _forSale
  ) external returns(uint256);

  // Allows someone to mint an HASHIMA on behalf of another user.
  function mintFor(
    uint8 _stars,
    string memory _uri,
    string memory _nonce,
    uint256 _price,
    bool _forSale,
    address _receiver
  ) external returns(uint256);

  function getTotal() external view returns(uint256);

  function check() external view returns(uint256, uint256);

  function buy(uint256 _tokenId) external payable returns(bool);

  function toggleForSale(uint256 _tokenId) external;

  function changePrice(uint256 _tokenId, uint256 _price) external;

  function changePriceAndStatus(uint256 _tokenId, uint256 _price) external;

}
