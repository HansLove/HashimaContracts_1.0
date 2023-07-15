// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IHashima.sol";

/**
  Hashima Protocol
  @dev ERC721 token with proof of work inyected in the structure.
  by: Aaron Tolentino*/
  abstract contract ERC721HashimaO is ERC721URIStorage,IHashima{

  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  using Strings for uint256;


  // numero de bloque en la que se inicio el protocolo
  mapping(address=>uint256) internal randomizer;

  // timestamp al momento de arrancar el protocolo
  mapping(address=>uint256) internal timing;

  mapping(uint256=>Hashi) DATA;

  function init() public override returns (uint256, uint256) {
    uint256 _timing = block.timestamp;
    // Generate a random seed using a combination of various factors.
    bytes32 seed = keccak256(
        abi.encodePacked(
            _tokenIds.current(),
            _timing,
            block.coinbase,
            block.difficulty
            // block.prevrandao
        )
    );

    // Generate a random number within the desired range
    uint256 _randomizer = uint256(seed) % (_tokenIds.current() + 100);

    // randomizer[msg.sender] = _randomizer;
    // timing[msg.sender] = _timing;

    randomizer[tx.origin] = _randomizer;
    timing[tx.origin] = _timing;

    emit InitProtocol(_randomizer, _timing);

    return (_randomizer, _timing);
  }


  function _beforeTokenTransfer(address from,address to,uint256 tokenId,uint256 batchSize)internal virtual override{
          require(batchSize>0);
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
  modifier proofOfWork(string memory _data,string memory _nonce, uint256 _stars,address _receiver){
      require(_stars>0&&_stars<=32,"At least 1 star");

      bool respuesta=true;
      // calculate sha256 of the inputs
      //this hash must start with a number of 0's
      bytes32 _hashFinal=sha256(abi.encodePacked(
        _data,
        _nonce,
        Strings.toString(randomizer[msg.sender]),
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

  /**Register the Hashima in the blockchain
  @param _uri:metadata attach to the Hashima
  @param _receiver:Who will get the Hashima
  @param _stars:Number of stars(hash power)
  @param _nonce:Proof of work unique number
  @param _price:Price in wei
  @param _forSale:Price in wei
  */
  function register(
    string memory _uri,
    address _receiver,
    uint8 _stars,
    string memory _nonce,
    uint256 _price,
    bool _forSale
    )internal 
    proofOfWork(_uri,_nonce,_stars,_receiver) returns(uint256){
      
      _tokenIds.increment();
        // new Hashima ID
      uint256 newItemId = _tokenIds.current();
      require(!_exists(newItemId),'cannot exist');

      Hashi memory newHashima= Hashi(
          newItemId,//token id of hashima
          payable(_receiver),//current owner
          payable(address(0)),//previous owner(for staking)
          _stars,//number of 0 in the hash
          randomizer[msg.sender],//block.number at Init()
          timing[msg.sender],//block.timestamp at Init()
          _nonce,//unique number for proof of work
          _price,
          _forSale
      );

      DATA[newItemId] = newHashima;

      _mint(_receiver, newItemId);
      // _setTokenURI(newItemId, _uri);
      
      // Return ID
      return newItemId;

  }

  /**Total amount of Hashimas*/
  function getTotal()public view override returns(uint256){
        return _tokenIds.current();
  }    

  // Return Hashima in mapping
  function get(uint256 _index)public view override returns(Hashi memory){
        return DATA[_index];
  }
  
  //Returns data needed for proof of work
  function check()public view override returns(uint256,uint256){
        return (randomizer[msg.sender],timing[msg.sender]);
  }

}
