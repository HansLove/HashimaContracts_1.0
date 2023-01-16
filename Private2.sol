// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Hashima2.sol";

/**
@dev
  Hashima smart conttract with metadata URI set by the user.
 */
abstract contract Private is ERC721Hashima{

    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIds;

    function getTotal()public view override returns(uint256){
        return _tokenIds.current();
    }    

    /**Called by the functions 'Mint' and 'MintFor' after proof of work check by the smart contract 
    implementing */
    function createHashimaItem(
        string memory _data,
        string memory _nonce,
        uint256 _stars,
        string memory _uri,
        uint256 _price,
        bool _forSale,
        address _receiver
        ) internal returns (uint256){

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

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

        
        _setTokenURI(newItemId,_uri);            

        // Hashi memory newHashima= Hashi(
        //     newItemId,//token id of hashima
        //     _data,//string pick by the miner, add randomness to proof of work
        //     payable(_receiver),
        //     payable(address(0)),
        //     _stars,
        //     tolerance[msg.sender],
        //     _nonce,
        //     _price,
        //     _forSale
        // );

        return newItemId;

    }

}
