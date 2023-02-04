// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Hashima.sol";

/**
  Hashima Protocol
  Hashimon, Game-Fi on top of Hashima

  This contract is in charge of the Counter update
 * @dev ERC721 token with proof of work inyected in the structure.
 by: Aaron Tolentino*/
  
abstract contract DNA is ERC721Hashima{

    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIds;

    function getTotal()public view override returns(uint256){
        return _tokenIds.current();
    }    

    // function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    //         uint8 i = 0;
    //         while(i < 32 && _bytes32[i] != 0) {
    //             i++;
    //         }
    //         bytes memory bytesArray = new bytes(i);
    //         for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
    //             bytesArray[i] = _bytes32[i];
    //         }
    //         return string(bytesArray);
    // }

    function createHashimaItem(
        string memory _data,
        string memory _nonce,
        uint256 _stars,
        uint256 _price,bool _forSale,address _receiver)internal virtual returns (uint256){

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(_receiver, newItemId);

        // bytes32 _uri=keccak256(abi.encodePacked(msg.sender,newItemId,_data,block.number));
        // string memory dna=bytes32ToString(_uri);

        // _setTokenURI(newItemId,dna);

        /**register Hashima in mapping metadata.
        register() checks proof of work &
        the id uniqueness. */
        register(
            newItemId,
            _data,
            _receiver,
            _stars,
            _nonce,
            _price,
            _forSale);


        return newItemId;

    }   
}