// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Hashima.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Auction is ReentrancyGuard {
  
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    struct StructAuction {
        uint256 periodoSubasta; //periodo de subasta en numero de bloques
        uint256 minPrice;//en wei
        uint256 nftHighestBid;//la apuesta mas grande 
        address nftHighestBidder;
        address nftSeller;
        bool active;

    }

    mapping(uint256=>bool) hashimaOnAction;
    mapping(uint256=>StructAuction) auctions;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    Hashima private hashima;

    constructor(Hashima _hashima){
        hashima=_hashima;
    }

    modifier isHashimaOwner(uint256 tokenId){
        address _owner=hashima.ownerOf(tokenId);
        require(_owner==msg.sender,'Only hashiowner');
        _;
    }


    function NewAuction(
        uint256 tokenId,
        uint256 _tolerance,
        uint256 _minPrice)isHashimaOwner(tokenId) nonReentrant() public{

        require(!hashimaOnAction[tokenId],'this hashima is on bid');
        require(_tolerance>100,'At leats 100 blocks');
        require(_minPrice>0,'Put somenthing on price');

        StructAuction memory _newAuction=StructAuction(
            block.number+_tolerance,//periodo de subasta
            _minPrice,//precio minimo
            0,//apuesta mas grande
            address(0),//el que aposto mas
            msg.sender,//nft seller
            true//activate
            );

        auctions[tokenId]=_newAuction;
        hashimaOnAction[tokenId]=true;

        //First transfer ownership to this contract
        //and then change the 'forSale' in case is on.
        hashima.transferFrom(msg.sender, address(this), tokenId);

        // bool forSale=hashima.getHashima(tokenId).forSale;
        // if(forSale){
        //     hashima.toggleForSale(tokenId,0);
        // }
        
    }


    function bid(uint256 tokenId) public payable {
        StructAuction memory _auction=auctions[tokenId];
        uint256 blockTime=_auction.periodoSubasta;
        uint256 _highestBid=_auction.nftHighestBid;
        address _high_bidder=_auction.nftHighestBidder;

        require(_auction.active,'Not activate');
        require(block.number <= blockTime,"Auction already ended");
        require(msg.value > _highestBid,"There already is a higher bid.");

        if (_highestBid != 0) {
            pendingReturns[_high_bidder] += _highestBid;
        }

        _auction.nftHighestBidder = msg.sender;
        _auction.nftHighestBid= msg.value;

        auctions[tokenId]=_auction;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {    
            pendingReturns[msg.sender] = 0;
            (bool _answer,)=payable(msg.sender).call{value:amount}("");
            if (!_answer) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    //esta funciona la llama el usuario al termionar el tiempo de subasta
    function auctionEnd(uint256 tokenId) public{
        StructAuction memory _auction=auctions[tokenId];
        address _highestBidder=_auction.nftHighestBidder;
        address _nftSeller=_auction.nftSeller;
        uint256 _high_bid=_auction.nftHighestBid;
        uint256 block_time=_auction.periodoSubasta;

        require(block.number > block_time, "Auction not yet ended.");
        require(_auction.active, "auctionEnd has already been called.");

        if(_highestBidder==address(0)){
            //nadie puso dinero, devolver al propietario
           _auction.active=false;
            auctions[tokenId]=_auction;
            hashimaOnAction[tokenId]=false;
            hashima.transferFrom(address(this), _nftSeller, tokenId);
            emit AuctionEnded(_nftSeller, _high_bid);  
        }else{        
            (bool sent, ) = _nftSeller.call{value: _high_bid}("");
            if(sent){
                _auction.active=false;
                auctions[tokenId]=_auction;
                hashimaOnAction[tokenId]=false;
                hashima.transferFrom(address(this), _highestBidder, tokenId);
                emit AuctionEnded(_highestBidder, _high_bid);
            }
        }
         
    }


    function getMaxBid(uint256 tokenID)public view returns(uint256){
        return auctions[tokenID].nftHighestBid;
    }

    function getMinPrice(uint256 tokenID)external view returns(uint256){
        return auctions[tokenID].minPrice;
    }

    function onAuction(uint256 tokenID)external view returns(bool){
        return hashimaOnAction[tokenID];
    }


    function period(uint256 tokenID)external view returns(uint256){
        return auctions[tokenID].periodoSubasta-block.number;
    }
}