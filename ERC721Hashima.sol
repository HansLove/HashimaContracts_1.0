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

  // numero de bloque en la que se inicio el protocolo
  mapping(address=>uint256) internal tolerance;

  // timestamp al momento de arrancar el protocolo
  mapping(address=>uint256) internal timing;
  //check the string use by the user is not repeat
  mapping(string=>bool)public _names;

  mapping(uint256=>Hashi) DATA;

  modifier onlyHashimaOwner(uint256 _tokenId){
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner == msg.sender,'only the hashima owner');
    _;
  }
  
  function Init()public override returns(uint256,uint256){
        uint256 _block=block.number;
        uint256 _timing=block.timestamp;
        tolerance[msg.sender]=_block;
        timing[msg.sender]=_timing;
        // event for external listener
        emit InitProtocol(_block,_timing);
        // return values for another smart contract interactions
        return (_block,_timing);
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
  1.Check tolerance is not 0. 
  2.Tolerance plus BLOCK TOLERANCE has to be more than the current block
  3.The proof of work data has to be unique in this smart contract.
  4.Sender cannot be 0
  5.Number of stars cannot be 0
  6.Price at least 1 wei
  */
  modifier checkMintingData(string memory _data,uint256 _stars,uint256 _price){
      require(tolerance[msg.sender]!=0,"Tolerance cannot be 0");
      require(tolerance[msg.sender]+BLOCK_TOLERANCE>block.number,"Tolerance is expire");
      require(_names[_data]==false,"Not unique data");
      require(msg.sender != address(0));
      require(_stars>0,"At least 1 star");
      require(_price>0,"Price cannot be 0");
    _;
  }
  
  /**
  Proof of work function inspired in Bitcoin by 
  Satoshi Nakamoto & Hashcash by Adam Back*/
  function proofOfWork(
    string memory _data,
    string memory _nonce,
    uint256 _stars)internal view returns(bool,bytes32){
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
      return (respuesta,_hashFinal);
  }

  function register(
    uint256 newItemId,
    string memory _data,
    address _receiver,
    uint256 _stars,
    string memory _nonce,
    uint256 _price,
    bool _forSale
    )internal{
      
      (bool respuesta,)=proofOfWork(_data,_nonce,_stars);
      require(respuesta,'incorrect proof of work');
      require(!_exists(newItemId),'cannot be');

      Hashi memory newHashima= Hashi(
          newItemId,//token id of hashima
          _data,//string pick by the miner, add randomness to proof of work
          payable(_receiver),
          payable(address(0)),
          _stars,
          tolerance[msg.sender],
          _nonce,
          _price,
          _forSale
      );

      _mint(_receiver, newItemId);
      _names[_data]=true; 
      DATA[newItemId] = newHashima;

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