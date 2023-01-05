// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IHashima.sol";


/**
  Hashima Protocol
 * @dev ERC721 token with proof of work inyected in the structure.
 by: Aaron Tolentino
 */
  abstract contract ERC721Hashima is ERC721URIStorage,IHashima{

  using Strings for uint256;

  uint256 public BLOCK_TOLERANCE=200;

  mapping(address=>uint256) internal tolerance;
  //check the string use by the user is not repeat
  mapping(string=>bool)public _names;

  mapping(uint256=>Hashi) DATA;

  function Init()public override returns(uint256){
        uint256 _block=block.number;
        tolerance[msg.sender]=_block;
        emit GameStart(_block);
        return _block;
  }

  function _beforeTokenTransfer(address from,address to,uint256 tokenId)internal virtual override{
          Hashi memory _hashima = DATA[tokenId];
          // update the token's previous owner
          _hashima.previousOwner = payable(from);
          // update the token's current owner
          _hashima.currentOwner =payable(to);
          DATA[tokenId] = _hashima;
  }
  
  modifier onlyHashimaOwner(uint256 _tokenId){
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner == msg.sender,'only the hashima owner');
    _;
  }
  
  modifier checkMintingData(string memory _data,uint256 _stars,uint256 _price){
      require(tolerance[msg.sender]!=0,"Tolerance cannot be 0");
      require(tolerance[msg.sender]+BLOCK_TOLERANCE>block.number,"Tolerance is expire");
      require(_names[_data]==false,"Not unique data");
      require(msg.sender != address(0));
      require(_stars>0,"At least 1 star");
      require(_price>0,"Price cannot be 0");
    _;
  }
  
  function proofOfWork(
    string memory _data,
    string memory _nonce,
    uint256 _stars)internal view returns(bool,bytes32){
      bool respuesta=true;
      bytes32 _hashFinal=sha256(abi.encodePacked(
        _data,
        _nonce,
        Strings.toString(tolerance[msg.sender])));
      
      for (uint256 index = 0; index < _stars; index++) {
        if (_hashFinal[index]!=0x00) {
                respuesta=false;  
            }
      }
      return (respuesta,_hashFinal);
  }

  function get(uint256 _index)public view override returns(Hashi memory){
        return DATA[_index];
  }

  function checkTolerance()public view override returns(uint256){
        return tolerance[msg.sender];
  }

}