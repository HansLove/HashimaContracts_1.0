// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Hashima.sol";

/**
  Hashima Protocol
 * @dev Market structure for a Hashima
 by: Aaron Tolentino*/
  
abstract contract Market is ERC721Hashima{

  // change the market state of the Hashima
  function toggleForSale(uint256 _tokenId)override public onlyHashimaOwner(_tokenId){
    require(msg.sender != address(0));
    require(_exists(_tokenId));

    Hashi memory _hashima = DATA[_tokenId];

    // if token's forSale is false make it true and vice versa
    if(_hashima.forSale) {
      _hashima.forSale = false;
    } else {
      _hashima.forSale = true;
    }

    // set and update that token in the mapping
    DATA[_tokenId] = _hashima;
  }

  //only changes the price
  function changePrice(uint256 _tokenId,uint256 _price)override external onlyHashimaOwner(_tokenId){
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    require(_price>0,'price cannot be 0');

    Hashi memory _hashima = DATA[_tokenId];

    _hashima.price = _price;
    
    DATA[_tokenId] = _hashima;
  }

  //change price and market state in the same transaction
  function changePriceAndStatus(uint256 _tokenId,uint256 _price)override external onlyHashimaOwner(_tokenId){
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    // the price at least 1 wei
    require(_price>0,'price cannot be 0');

    Hashi memory _hashima = DATA[_tokenId];
    // if token's forSale is false make it true and vice versa
    if(_hashima.forSale) {
      _hashima.forSale = false;
    } else {
      _hashima.forSale = true;
    }
    // change the price in metadata
    _hashima.price = _price;
    // save in metadata mapping
    DATA[_tokenId] = _hashima;
  }

  // buy token in case is availiable
  function buy(uint256 _tokenId)override external payable returns(bool){
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
    // if transaction is sucessful, transfer Hashima
    _transfer(tokenOwner, msg.sender, _tokenId);
    
    return sent;
  }  

}