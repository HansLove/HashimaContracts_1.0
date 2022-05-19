// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract NoHashima is ERC721{

    constructor() ERC721("NotHashima", "NOTHASHIMA") {}


  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIds;
  uint256 BLOCK_TOLERANCE=200;

  mapping(address=>uint256) private tolerance;
  //check the string use by the user is not repeat
  mapping(string=>bool)public _names;


  event GameStart(uint256 _blocknumber);

  event Minted(bool respuesta,bytes32 hashResultado);


  struct Hashi {
      uint256 tokenId;
      string tokenURI;
      address payable currentOwner;
      address payable previousOwner;
      uint256 stars;
      uint256 blockTolerance;
      uint256 blockEnd;
      string nonce;
  }
  
  mapping(uint256=>Hashi) _hashis ;


  function getHashima(uint256 _index)public view returns(Hashi memory){
        return _hashis[_index];
  }

  function getStars(uint256 _index)public view returns(uint256){
    return _hashis[_index].stars;
  }

  function getProofOfWorkData(uint256 _index)public view 
  returns(string memory,uint256,string memory,uint256,uint256){
        string memory _data=_hashis[_index].tokenURI;
        uint256 _stars=_hashis[_index].stars;
        uint256 _tolerance=_hashis[_index].blockTolerance;
        uint256 _endBlock=_hashis[_index].blockEnd;
        string memory _nonce=_hashis[_index].nonce;
        return (_data,_stars,_nonce,_tolerance,_endBlock);
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
        // return _block;
  }


  function Mint(
    uint256 _stars,
    string memory _data,
    string memory _nonce) external  
    // returns(bool,bytes32,uint256) 
    {
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
              _stars);


      
      }
      
      emit Minted(respuesta,_hashFinal);
      // return(respuesta,_hashFinal,_id);


  }


  function createHashimaItem(
    uint256  toleranceBlock,
    string memory _data,
    string memory _nonce,
    uint256 _stars) public virtual returns (uint256){

    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _mint(msg.sender, newItemId);


    Hashi memory newHashima= Hashi(
    _tokenIds.current(),//token id of hashima
    _data,//string pick by the miner
    payable(msg.sender),
    payable(address(0)),
    _stars,
    toleranceBlock,
    block.number,
    _nonce
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




  function checkingHash(
    string memory _data,
    string memory _nonce,
    uint256 _tolerance,
    uint256 _stars)public pure returns(bool,bytes32){
      bytes32 _hashFinal=sha256(abi.encodePacked(_data,_nonce,Strings.toString(_tolerance)));
      bool respuesta=true;

      for (uint256 index = 0; index < _stars; index++) {
      if (_hashFinal[index]!=0x00) {
              respuesta=false;  
          }
      
      }
      return (respuesta,_hashFinal);

  }

}