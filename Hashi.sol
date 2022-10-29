// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Hashima.sol";
import "./ERC721Hashima.sol";

contract Hashi is ERC20Burnable{
    using SafeMath for uint256;
    mapping(address => mapping(uint256=>uint256)) public checkpoints;
    mapping(uint256 => bool) public has_deposited;
    mapping(uint256 => address) public staking_accounts;

    Hashima private hashimaContract;

    constructor(Hashima _contrato) ERC20("Hashi", "HASHI"){
        hashimaContract = Hashima(_contrato);

    }

    function aprovar(uint256 tokenId)external{
        hashimaContract.approve(address(this), tokenId);
    }

    function deposit(uint256 tokenId) external{
        require (msg.sender == hashimaContract.ownerOf(tokenId), 'Sender must be owner');
        require (!has_deposited[tokenId], 'Sender already deposited');
        
        //La altura del bloque de partida
        checkpoints[msg.sender][tokenId] = block.number;
        staking_accounts[tokenId]=msg.sender;
        has_deposited[tokenId]=true;
        
        hashimaContract.transferFrom(msg.sender, address(this), tokenId);
        bool forSale=hashimaContract.getHashima(tokenId).forSale;
        
        if(forSale){
            hashimaContract.toggleForSale(tokenId);
        }
        
   }

    function withdraw(uint256 tokenId) external{
        require(has_deposited[tokenId], 'No tokens to withdarw');
        require(staking_accounts[tokenId]==msg.sender,'Only the Staker');
        collect(msg.sender,tokenId);
        hashimaContract.transferFrom(address(this), msg.sender, tokenId);
        
        has_deposited[tokenId]=false;
    }

    function collect(address beneficiary,uint256 tokenId) public{
        uint256 reward = calculateReward(beneficiary,tokenId);
        checkpoints[beneficiary][tokenId] = block.number;      
        _mint(msg.sender, reward);
    }

    function hashimaOnStaking(uint256 tokenId)public view returns(bool){
        return has_deposited[tokenId];
    }

    function calculateReward(address beneficiary,uint256 tokenId) public view returns(uint256){
        if(!has_deposited[tokenId])
        {
            return 0;
        }
        uint256 _stars=hashimaContract.getHashima(tokenId).stars;
        uint256 pesoEstrella=_stars*_stars*1000**_stars/64-_stars;
        uint256 checkpoint = checkpoints[beneficiary][tokenId];
        return pesoEstrella*(block.number-checkpoint);
    }
}