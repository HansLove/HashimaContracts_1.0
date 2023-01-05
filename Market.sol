// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Hashima.sol";

/**
  Hashima Protocol
 * @dev Market structure for a Hashima
 by: Aaron Tolentino*/
  
abstract contract Market is ERC721Hashima{

  function toggleForSale(uint256 _tokenId,uint256 _price)override public onlyHashimaOwner(_tokenId){
    require(msg.sender != address(0));
    require(_exists(_tokenId));

    Hashi memory _hashima = DATA[_tokenId];

    // if token's forSale is false make it true and vice versa
    if(_hashima.forSale) {
      _hashima.forSale = false;
    } else {
      _hashima.forSale = true;
    }

    if(_price>0)_hashima.price = _price;
    // set and update that token in the mapping
    DATA[_tokenId] = _hashima;
  }

  function changePrice(uint256 _tokenId,uint256 _newPrice)override external onlyHashimaOwner(_tokenId){
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    require(_newPrice>0,'price cannot be 0');

    Hashi memory _hashima = DATA[_tokenId];

    _hashima.price = _newPrice;
    _hashima.forSale = !_hashima.forSale;
    
    DATA[_tokenId] = _hashima;
  }

  function changePriceAndState(uint256 _tokenId,uint256 _newPrice)external onlyHashimaOwner(_tokenId){
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    require(_newPrice>0,'price cannot be 0');

    Hashi memory _hashima = DATA[_tokenId];

    _hashima.price = _newPrice;
    
    DATA[_tokenId] = _hashima;
  }

  function buyToken(uint256 _tokenId)override public payable returns(bool){
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);

    require(tokenOwner != address(0));
    require(tokenOwner != msg.sender);

    Hashi memory _hashima = DATA[_tokenId];
    
    require(msg.value >= _hashima.price,'price is not correct');
    require(_hashima.forSale,'hashima is not in sale');
    
    // get owner of the token
    address payable sendTo = _hashima.currentOwner;
    // send token's worth of native token to the owner
    (bool sent, ) = sendTo.call{value: msg.value}("");
    require(sent,'transaction not succesful');
    //Hashima for sale is set to false.
    _hashima.forSale =false;
    //Save in mapping
    DATA[_tokenId] = _hashima;
    _transfer(tokenOwner, msg.sender, _tokenId);
    
    return sent;
  }  

}