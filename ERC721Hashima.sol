// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IHashima.sol";

/**
  Hashima Protocol
 * @dev ERC721 token with proof of work inyected in the structure.
 by: Aaron Tolentino*/
  abstract contract ERC721Hashima is 
  // ERC721
  ERC721URIStorage
  ,IHashima{

  using Counters for Counters.Counter;

  Counters.Counter internal _tokenIds;

  using Strings for uint256;

  // uint256 public BLOCK_TOLERANCE=200;

  // numero de bloque en la que se inicio el protocolo
  mapping(address=>uint256) internal tolerance;

  // timestamp al momento de arrancar el protocolo
  mapping(address=>uint256) internal timing;

  mapping(uint256=>Hashi) DATA;

  modifier onlyHashimaOwner(uint256 _tokenId){
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner == msg.sender,'only the hashima owner');
    _;
  }
    /** 
  1.Check tolerance is not 0. 
  2.Tolerance plus BLOCK TOLERANCE has to be more than the current block
  3.The proof of work data has to be unique in this smart contract.
  4.Sender cannot be 0
  5.Number of stars cannot be 0
  6.Price at least 1 wei
  */
  modifier checkMintingData(string memory _uri,uint256 _stars,uint256 _price){
      require(tolerance[msg.sender]!=0);
      require(timing[msg.sender]!=0);
      require(timing[msg.sender]+600>block.timestamp,"Timing is expire");
      require(bytes(_uri).length >= 1, "Data must be at least 1 byte long");
      require(msg.sender != address(0));
      require(_stars>0,"At least 1 star");
      require(_price>0,"Price cannot be 0");
    _;
  }
  
  
  function init()public override returns(uint256,uint256){
        uint256 _timing=block.timestamp;
        uint256 _randomizer=uint256(keccak256(abi.encodePacked(
        block.timestamp, 
        block.coinbase,
        block.number)))%(_tokenIds.current()+100);

        tolerance[msg.sender]=_randomizer;
        timing[msg.sender]=_timing;
        // event for external listener
        emit InitProtocol(_randomizer,_timing);
        // return values for another smart contract interactions
        return (_randomizer,_timing);
  }

  function _beforeTokenTransfer(address from,address to,uint256 tokenId)internal virtual override{
          Hashi memory _hashima = DATA[tokenId];
          // update the token's previous owner
          _hashima.previousOwner = payable(from);
          // update the token's current owner
          _hashima.currentOwner =payable(to);

          //update the state of market if it´s for sale
          if(_hashima.forSale)_hashima.forSale =false;

          DATA[tokenId] = _hashima;
  }
  

  /**
  Proof of work function inspired in Bitcoin by 
  Satoshi Nakamoto & Hashcash by Adam Back*/
  modifier proofOfWork(string memory _data,string memory _nonce, uint256 _stars){
      bool respuesta=true;
      // calculate sha256 of the inputs
      //this hash must start with a number of 0's
      bytes32 _hashFinal=sha256(abi.encodePacked(
        _data,
        _nonce,
        Strings.toString(tolerance[msg.sender]),
        Strings.toString(timing[msg.sender])
        ));
      
      for (uint256 index = 0; index < _stars; index++) {
        if (_hashFinal[index]!=0x00) {
                respuesta=false;  
            }
      }
      require(respuesta,'invalid proof of work');
    _;
  }


  function register(
    string memory _uri,
    address _receiver,
    uint256 _stars,
    string memory _nonce,
    uint256 _price,
    bool _forSale
    )internal 
    proofOfWork(_uri,_nonce,_stars)  
    returns(uint256){
      
      _tokenIds.increment();
        // new Hashima ID
      uint256 newItemId = _tokenIds.current();
      require(!_exists(newItemId),'cannot exist');

      _mint(_receiver, newItemId);
      _setTokenURI(newItemId, _uri);
      


      Hashi memory newHashima= Hashi(
          newItemId,//token id of hashima
          payable(_receiver),//current owner
          payable(address(0)),//previous owner(for staking)
          _stars,//number of 0 in the hash
          tolerance[msg.sender],//block.number at Init()
          timing[msg.sender],//block.timestamp at Init()
          _nonce,//unique number for proof of work
          _price,
          _forSale
      );

      DATA[newItemId] = newHashima;
      
      // Return ID
      return newItemId;

  }


  function getTotal()public view override returns(uint256){
        return _tokenIds.current();
  }    


  // return Hashima in mapping
  function get(uint256 _index)public view override returns(Hashi memory){
        return DATA[_index];
  }
  
  //returns data needed for proof of work
  function check()public view override returns(uint256,uint256){
        return (tolerance[msg.sender],timing[msg.sender]);
  }

}
