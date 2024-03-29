// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IHashima.sol";

abstract contract ERC721Hashima is ERC721, IHashima {

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
    // require(timing[user]!=0&&timing[user]+600>_timing);
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

    randomizer[msg.sender] = _randomizer;
    timing[msg.sender] = _timing;

    // randomizer[tx.origin] = _randomizer;
    // timing[tx.origin] = _timing;

    emit InitProtocol(_randomizer, _timing);

    return (_randomizer, _timing);
  }


  function _beforeTokenTransfer(address from,address to,uint256 tokenId
  ,uint256 batchSize
  )internal virtual override{
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
  // modifier proofOfWork(string memory _data,string memory _nonce, uint256 _stars){
  //     require(_stars>0&&_stars<=32,"At least 1 star");

  //     bool respuesta=true;
  //     // calculate sha256 of the inputs
  //     //this hash must start with a number of 0's
  //     bytes32 _hashFinal=sha256(abi.encodePacked(
  //       _data,
  //       _nonce,
  //       Strings.toString(randomizer[msg.sender]),
  //       Strings.toString(timing[msg.sender])
  //       ));
      
  //     for (uint256 index = 0; index < _stars; index++) {
  //       if (_hashFinal[index]!=0x00) {
  //               respuesta=false;  
  //           }
  //     }
  //     require(respuesta,'invalid proof of work');
  //   _;
  // }

  //   modifier proofOfWork(string memory _data, string memory _nonce, uint256 _stars) {
  //     require(_stars > 0 && _stars <= 32, "Invalid number of stars");
  //     bytes32 hash = sha256(abi.encodePacked(_data, _nonce, Strings.toString(randomizer[msg.sender]), Strings.toString(timing[msg.sender])));
  //     require(uint256(hash) < (2 ** (256 - _stars)), "Invalid proof of work"); // Difficulty: _stars leading zeroes
  //     _;
  // }


  //     modifier checkMintingData(string memory _uri, uint256 _stars, uint256 _price) {
  //       require(randomizer[msg.sender] != 0, "Not randomizer");
  //       require(timing[msg.sender] != 0, "Not timing");
  //       require(timing[msg.sender] + 600 > block.timestamp, "Timing is expired");
  //       require(bytes(_uri).length >= 1, "Data must be at least 1 byte long");
  //       require(msg.sender != address(0), "Invalid sender address");
  //       require(_price > 0, "Price cannot be 0");
  //       _;
  //   }
    /** 
    1.Check randomizer is not 0. 
    2.Tolerance plus BLOCK TOLERANCE has to be more than the current block
    3.The proof of work data has to be unique in this smart contract.
    4.Sender cannot be 0
    5.Number of stars cannot be 0
    6.Price at least 1 wei
    */
    modifier checkWorkAndData(
        uint256 _stars,
        uint256 _price,
        string memory _data,
        string memory _nonce
    ) {
        // require(randomizer[msg.sender] != 0, "Not randomizer");
        require(timing[msg.sender] != 0&&randomizer[msg.sender] != 0&&bytes(_data).length >= 1, "Not data");
        require(timing[msg.sender] + 600 > block.timestamp, "Timing is expired");
        require(_price > 0, "Price cannot be 0");
        // require(bytes(_data).length >= 1, "Data must be at least 1 byte long");
        // require(msg.sender != address(0), "Invalid sender address");

        // bytes32 hash = sha256(abi.encodePacked(_data, _nonce, Strings.toString(randomizer[msg.sender]), Strings.toString(timing[msg.sender])));
        // bytes32 hash = sha256(abi.encodePacked(_data, _nonce, Strings.toString(randomizer[msg.sender]), Strings.toString(timing[msg.sender])));
        // require(uint256(hash) < (2 ** (256 - _stars)), "Invalid proof of work"); // Difficulty: _stars leading zeroes
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
    checkWorkAndData(_stars,_price,_uri,_nonce) 
    returns(uint256){
      
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
      // Mining data already used, convert to 0.
      timing[msg.sender]=0;
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
