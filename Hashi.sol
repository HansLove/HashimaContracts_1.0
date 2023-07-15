// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721Hashima.sol";
import "./IHashima.sol";

contract Hashi is ERC20Burnable{
    using SafeMath for uint256;
    mapping(address => mapping(uint256=>uint256)) public checkpoints;
    mapping(address=>mapping(uint256 => bool)) public has_deposited;
    mapping(uint256 => address) public staking_accounts;

    // Nakamoto private hashimaContract;

    constructor() ERC20("Hashi", "HASHI"){

    }

    function aprovar(address _contract,uint256 tokenId)external{
        ERC721Hashima(_contract).approve(address(this), tokenId);
    }

    function deposit(address _contract,uint256 tokenId) external{
        require (msg.sender == ERC721Hashima(_contract).ownerOf(tokenId), 'Sender must be owner');
        require (!has_deposited[_contract][tokenId], 'Sender already deposited');
        
        //La altura del bloque de partida
        checkpoints[msg.sender][tokenId] = block.number;
        staking_accounts[tokenId]=msg.sender;
        has_deposited[_contract][tokenId]=true;
        
        ERC721Hashima(_contract).transferFrom(msg.sender, address(this), tokenId);
        bool forSale=ERC721Hashima(_contract).get(tokenId).forSale;
        
        if(forSale)ERC721Hashima(_contract).toggleForSale(tokenId);
        
   }

    function withdraw(address _contract,uint256 tokenId) external{
        require(has_deposited[_contract][tokenId], 'No tokens to withdarw');
        require(staking_accounts[tokenId]==msg.sender,'Only the Staker');
        collect(_contract,msg.sender,tokenId);
        ERC721Hashima(_contract).transferFrom(address(this), msg.sender, tokenId);
        
        has_deposited[_contract][tokenId]=false;
    }

    function collect(address _contract,address beneficiary,uint256 tokenId) public{
        uint256 reward = calculateReward(_contract,beneficiary,tokenId);
        checkpoints[beneficiary][tokenId] = block.number;      
        _mint(msg.sender, reward);
    }

    function hashimaOnStaking(address _contract,uint256 tokenId)public view returns(bool){
        return has_deposited[_contract][tokenId];
    }

    function calculateReward(address _contract,address beneficiary,uint256 tokenId) public view returns(uint256){
        if(!has_deposited[_contract][tokenId])
        {
            return 0;
        }
        uint256 _stars=ERC721Hashima(_contract).get(tokenId).stars;
        uint256 pesoEstrella=_stars*_stars*1000**_stars/64-_stars;
        uint256 checkpoint = checkpoints[beneficiary][tokenId];
        return pesoEstrella*(block.number-checkpoint);
    }

        /**
    Proof of work function inspired in Bitcoin by 
    Satoshi Nakamoto & Hashcash by Adam Back*/
    function proofOfWork(
        string memory _data,
        string memory _nonce,
        uint256 _stars,
        uint256 _tolerance,
        uint256 _timing
        )internal pure returns(bool){
        bool respuesta=true;
        // calculate sha256 of the inputs
        //this hash must start with a number of 0's
        bytes32 _hashFinal=sha256(abi.encodePacked(
            _data,
            _nonce,
            Strings.toString(_tolerance),
            Strings.toString(_timing)
            ));
        
        for (uint256 index = 0; index < _stars; index++) {
            if (_hashFinal[index]!=0x00) {
                    respuesta=false;  
                }
        }
        return respuesta;
    }
}