// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IHashima.sol";



/**
 * @dev ERC721 token with hash power inyected.
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


  event GameStart(uint256 _blocknumber);

  event Minted(bool respuesta,bytes32 hashResultado);


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
  
  mapping(uint256=>Hashi) _hashis ;


  function getHashima(uint256 _index)public view returns(Hashi memory){
        return _hashis[_index];
  }

  function getStars(uint256 _index)public view returns(uint256){
    return _hashis[_index].stars;
  }

  function getTotal()public view returns(uint256){
    return _tokenIds.current();
  }

  function getProofOfWorkData(uint256 _index)public view 
  returns(string memory,uint256,string memory,uint256){
        string memory _data=_hashis[_index].data;
        uint256 _stars=_hashis[_index].stars;
        uint256 _tolerance=_hashis[_index].blockTolerance;
        string memory _nonce=_hashis[_index].nonce;
        return (_data,_stars,_nonce,_tolerance);
  }

  function _beforeTokenTransfer(address from,address to,uint256 tokenId)internal override{
          Hashi memory _hashima = _hashis[tokenId];
          // update the token's previous owner
          _hashima.previousOwner = payable(from);
          // update the token's current owner
          _hashima.currentOwner =payable(to);
          _hashis[tokenId] = _hashima;

  }
  



  function Init()public{
        uint256 _block=block.number;
        tolerance[msg.sender]=_block;
        emit GameStart(_block);

  }


  function Mint(
    uint256 _stars,
    string memory _data,
    string memory _nonce,
    string memory _uri,
    uint256 _price,
    bool _forSale
    )public virtual override{
      require(tolerance[msg.sender]+BLOCK_TOLERANCE>block.number,"tolerance is expire");
      require(_names[_data]==false,"name is busy");
      require(tolerance[msg.sender]!=0,"Tolerance cannot be 0");
      require(msg.sender != address(0));

      bool respuesta=true;
      uint256 _id=0;

      bytes32 _hashFinal=sha256(abi.encodePacked(_data,_nonce,Strings.toString(tolerance[msg.sender])));
      for (uint256 index = 0; index < _stars; index++) {
      if (_hashFinal[index]!=0x00) {
              respuesta=false;  
          }
      
      }
      if (respuesta) {
          //convierto la string utilizada a true para que no pueda ser utilizada.    
          _names[_data]=true; 

          _id=createHashimaItem(
              tolerance[msg.sender],
              _data,
              _nonce,
              _stars,
              _uri,
              _price,
              _forSale
              );


      }
      
      emit Minted(respuesta,_hashFinal);

  }


  function createHashimaItem(
    uint256  toleranceBlock,
    string memory _data,
    string memory _nonce,
    uint256 _stars,
    string memory _uri,
    uint256 _price,
    bool _forSale
    ) internal virtual returns (uint256){

    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    _mint(msg.sender, newItemId);
    _setTokenURI(newItemId,_uri);


    Hashi memory newHashima= Hashi(
    _tokenIds.current(),//token id of hashima
    _data,//string pick by the miner
    payable(msg.sender),
    payable(address(0)),
    _stars,
    toleranceBlock,
    _nonce,
    _price,
    _forSale
    );


    _hashis[newItemId] = newHashima;

    return newItemId;

  }

  function checkGame()public view returns(uint256){
        return tolerance[msg.sender];
  }
  
  function getBlockTolerance()public view returns(uint256){
        return BLOCK_TOLERANCE;

  }



  // switch between set for sale and set not for sale
  function toggleForSale(uint256 _tokenId,uint256 _newPrice) public {
    require(msg.sender != address(0));
    // require that token should exist
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);
    // check that token's owner should be equal to the caller of the function
    require(tokenOwner == msg.sender,'only the hashima owner');
    // get that token from all crypto boys mapping and create a memory of it defined as (struct => CryptoBoy)
    Hashi memory _hashima = _hashis[_tokenId];

    // if token's forSale is false make it true and vice versa
    if(_hashima.forSale) {
      _hashima.forSale = false;
    } else {
      _hashima.forSale = true;
      _hashima.price = _newPrice;
    }
    // set and update that token in the mapping
    _hashis[_tokenId] = _hashima;
  }
}