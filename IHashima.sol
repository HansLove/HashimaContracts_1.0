// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';


/**

By Aaron Tolentino */
interface IHashima is IERC721{

    //Metadata structure
    //tokenId:Unique number
    //data: Unique data for the PoW(proof of work) hash randomness
    //currentOwner:address of the owner
    //preciousOwner:address,required for staking
    //stars:number of 0's at the beginning of the hash 
    //blockTolerance:block in which the protocol was started
    //nonce:Unique number for PoW
    //price:price of the asset.Has to be more than 0
    //forSale:it is available in the market?
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
  
    /**called to initialize the protocol. 
    The block number and timestamp at the time of initialization 
    are stored in the mappings and an InitProtocol event is emitted. */
    event InitProtocol(uint256 _blocknumber,uint256 _timing);

    event Minted(bool respuesta,bytes32 hashResultado,uint256 id);

    /**
    Called by the user to set .
    This function gaves timing to the minting process.
     */
    function Init()external returns(uint256,uint256);    

    //Get all the data save in the blockchain. 
    //You can get the proof of work variables to 'check' the Hashima power
    function get(uint256 _index)external view returns(Hashi memory);

    // total amount of Hashimas.
    function getTotal()external view returns(uint256);

    // Returns data created inside contract for proof of work hash.
    //1.tolerance: block # where protocolo was init
    //2.timing: time stamp where protocolo was init
    function check()external view returns(uint256,uint256);

    /** Market function
    If Hashima is available user can buy it calling this function.
     */
    function buy(uint256 _tokenId)external payable returns(bool);

    /**@dev 
     Market function
    User can change the market status of the NFT(is available?)*/
    function toggleForSale(uint256 _tokenId) external;

    /** Market function 
    This function change the price.
    */
    function changePrice(uint256 _tokenId,uint256 _price) external;

    /** Market function 
    This function change the price and the sale state in the same transaction
    */
    function changePriceAndStatus(uint256 _tokenId,uint256 _price) external;

}