// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IHashima.sol";


/**
  Hashima Protocol
 * @dev ERC721 token with proof of work inyected in the structure.
 by: Aaron Tolentino
 */
  abstract contract ERC721Hashima is ERC721URIStorage,IHashima{

  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter internal _tokenIds;

  uint256 BLOCK_TOLERANCE=200;

  mapping(address=>uint256) private tolerance;
  //check the string use by the user is not repeat
  mapping(string=>bool)public _names;

  mapping(uint256=>Hashi) _hashis ;


  function Init()public override{
        uint256 _block=block.number;
        tolerance[msg.sender]=_block;
        emit GameStart(_block);

  }

  function _beforeTokenTransfer(address from,address to,uint256 tokenId)internal override{
          Hashi memory _hashima = _hashis[tokenId];
          // update the token's previous owner
          _hashima.previousOwner = payable(from);
          // update the token's current owner
          _hashima.currentOwner =payable(to);
          _hashis[tokenId] = _hashima;

  }
  
  function Mint(
    uint256 _stars,
    string memory _data,
    string memory _nonce,
    string memory _uri,
    uint256 _price,
    bool _forSale
    )public override {
      require(tolerance[msg.sender]!=0,"Tolerance cannot be 0");
      require(tolerance[msg.sender]+BLOCK_TOLERANCE>block.number,"Tolerance is expire");
      require(_names[_data]==false,"Not unique data");
      require(msg.sender != address(0));
      require(_stars>0,"At least 2 stars");
      require(_price>0,"Price cannot be 0");

      bool respuesta=true;
      uint256 _id=0;

      bytes32 _hashFinal=sha256(abi.encodePacked(_data,_nonce,Strings.toString(tolerance[msg.sender])));
      
      for (uint256 index = 0; index < _stars; index++) {
        if (_hashFinal[index]!=0x00) {
                respuesta=false;  
            }
    
      }
      
      if (respuesta) {
          //Convert '_data' string in true inside the mapping.   
          _names[_data]=true; 

          _id=createHashimaItem(
              _data,
              _nonce,
              _stars,
              _uri,
              _price,
              _forSale
            );
      }
      
      emit Minted(respuesta,_hashFinal,_id);
      

  }


  function createHashimaItem(
    string memory _data,
    string memory _nonce,
    uint256 _stars,
    string memory _uri,
    uint256 _price,
    bool _forSale
    ) internal returns (uint256){

    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    _mint(msg.sender, newItemId);
    _setTokenURI(newItemId,_uri);


    Hashi memory newHashima= Hashi(
    newItemId,//token id of hashima
    _data,//string pick by the miner
    payable(msg.sender),
    payable(address(0)),
    _stars,
    tolerance[msg.sender],
    _nonce,
    _price,
    _forSale
    );


    _hashis[newItemId] = newHashima;

    return newItemId;

  }

//////////////////----CHANGE MARKET STATE----/////////////////////

  function toggleForSale(uint256 _tokenId) public onlyHashimaOwner(_tokenId) override{
    require(msg.sender != address(0));
    require(_exists(_tokenId));

    Hashi memory _hashima = _hashis[_tokenId];

    // if token's forSale is false make it true and vice versa
    if(_hashima.forSale) {
      _hashima.forSale = false;
    } else {
      _hashima.forSale = true;
    }
    // set and update that token in the mapping
    _hashis[_tokenId] = _hashima;
  }

  function toggleForSaleAndPrice(uint256 _tokenId,uint256 _price) public onlyHashimaOwner(_tokenId) override{
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    require(_price>0,'price cannot be 0');

    Hashi memory _hashima = _hashis[_tokenId];

    // if token's forSale is false make it true and vice versa
    if(_hashima.forSale) {
      _hashima.forSale = false;
    } else {
      _hashima.forSale = true;
      
    }
    //This function main goal is change the price
    _hashima.price = _price;

    // set and update that token in the mapping
    _hashis[_tokenId] = _hashima;
  }

  function changePrice(uint256 _tokenId,uint256 _newPrice) public onlyHashimaOwner(_tokenId)  override {
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    require(_newPrice>0,'price cannot be 0');

    Hashi memory _hashima = _hashis[_tokenId];

    _hashima.price = _newPrice;
    
    _hashis[_tokenId] = _hashima;
  }

  function buyToken(uint256 _tokenId) public override payable returns(bool){
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);

    require(tokenOwner != address(0));
    require(tokenOwner != msg.sender);

    Hashi memory _hashima = _hashis[_tokenId];
    
    require(msg.value >= _hashima.price,'price has to be high');
    require(_hashima.forSale,'hashima is not in sale');
    
    // get owner of the token
    address payable sendTo = _hashima.currentOwner;
    // send token's worth of ethers to the owner
    (bool sent, ) = sendTo.call{value: msg.value}("");
    require(sent,'transaction not succesful');

    _transfer(tokenOwner, msg.sender, _tokenId);

    // update the token's previous owner
    _hashima.previousOwner = _hashima.currentOwner;
    // update the token's current owner
    _hashima.currentOwner =payable(msg.sender);

    //Change market state, so there is no possibility of quick buy
    _hashima.forSale=false;
    // set and update that token in the mapping
    _hashis[_tokenId] = _hashima;

    return sent;
  }

//////////////////----GETTERS----/////////////////////

  function getHashima(uint256 _index)public view override returns(Hashi memory){
        return _hashis[_index];
  }

  function getTotal()public view override returns(uint256){
    return _tokenIds.current();
  }

  function checkTolerance()public view override returns(uint256){
        return tolerance[msg.sender];
  }
  
  function getBlockTolerance()external view override returns(uint256){
        return BLOCK_TOLERANCE;
  }


///////////////---Modifiers----------------------------------------------------//////
  modifier onlyHashimaOwner(uint256 _tokenId){
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner == msg.sender,'only the hashima owner');
    _;
  }


}