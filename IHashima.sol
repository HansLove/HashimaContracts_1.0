// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IHashima is IERC721 {

  struct Hashi {
    uint256 tokenId;
    address payable currentOwner;
    address payable previousOwner;
    uint256 stars;
    uint256 blockTolerance;
    uint256 timing;
    string nonce;
    uint256 price;
    bool forSale;
  }

  event InitProtocol(uint256 _blocknumber, uint256 _timing);

  event Minted(bool respuesta, bytes32 hashResultado, uint256 id);

  // Start the Hashima protocol
  function init() external returns(uint256, uint256);    

  function get(uint256 _index) external view returns(Hashi memory);

  function mint(
    uint256 _stars,
    string memory _uri,
    string memory _nonce,
    uint256 _price,
    bool _forSale
  ) external returns(uint256);

  function mintFor(
    uint256 _stars,
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

  // function hashima(string memory _data, string memory _nonce) external view returns(bytes32);
}



/**
interface ERC721Hashima {
  function create(address to, uint256 tokenId, string memory data) external;
  function read(uint256 tokenId) external view returns (address, string memory);
}

contract MySupportsHashima {
  function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
    return _interfaceId == ERC721Hashima.interfaceId || _interfaceId == ERC721.interfaceId;
  }

      function checkHashimaSupport(address _contract) public view returns (bool) {
        bytes4 hashimaInterface = 0x77696474;
        return _contract.call(bytes4(keccak256("supportsInterface(bytes4)")), hashimaInterface);
    }
}

 */