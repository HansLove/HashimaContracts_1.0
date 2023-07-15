// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Nakamoto.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract OptionalAuction is ReentrancyGuard {
  
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // token id=>amount
    mapping(uint256 => uint256) BIDS;

    struct Offer{
        uint256 periodoSubasta; //periodo de subasta en numero de bloques
        uint256 amount;//la apuesta mas grande 
        address bidder;

    }

    mapping(uint256=>bool) hashimaOnAction;
    mapping(uint256=>Offer) OFFERS;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    Nakamoto private hashima;

    constructor(Nakamoto _hashima){
        hashima=_hashima;
    }

    modifier isHashimaOwner(uint256 tokenId){
        address _owner=hashima.ownerOf(tokenId);
        require(_owner==msg.sender,'Only hashiowner');
        _;
    }

    // hashima.transferFrom(msg.sender, address(this), tokenId);


    function newOffer(uint256 tokenId) public payable {

        uint256 _price=msg.value;
        Offer memory _auction=OFFERS[tokenId];

        uint256 _highestBid=_auction.amount;

        address _high_bidder=_auction.bidder;

        require(_price>BIDS[tokenId],'Put somenthing on price');

        if (_highestBid != 0) {
            pendingReturns[_high_bidder] += _highestBid;
        }

        _auction.bidder = msg.sender;
        _auction.amount= msg.value;

        OFFERS[tokenId]=_auction;
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

    // //esta funciona la llama el usuario al termionar el tiempo de subasta
    // function auctionEnd(uint256 tokenId) public{
    //     Offer memory _auction=auctions[tokenId];
    //     address _highestBidder=_auction.nftHighestBidder;
    //     address _nftSeller=_auction.nftSeller;
    //     uint256 _high_bid=_auction.nftHighestBid;
    //     uint256 block_time=_auction.periodoSubasta;

    //     require(block.number > block_time, "Auction not yet ended.");
    //     require(_auction.active, "auctionEnd has already been called.");

    //     if(_highestBidder==address(0)){
    //         //nadie puso dinero, devolver al propietario
    //        _auction.active=false;
    //         auctions[tokenId]=_auction;
    //         hashimaOnAction[tokenId]=false;
    //         hashima.transferFrom(address(this), _nftSeller, tokenId);
    //         emit AuctionEnded(_nftSeller, _high_bid);  
    //     }else{        
    //         (bool sent, ) = _nftSeller.call{value: _high_bid}("");
    //         if(sent){
    //             _auction.active=false;
    //             auctions[tokenId]=_auction;
    //             hashimaOnAction[tokenId]=false;
    //             hashima.transferFrom(address(this), _highestBidder, tokenId);
    //             emit AuctionEnded(_highestBidder, _high_bid);
    //         }
    //     }
         
    // }


    // function getMaxBid(uint256 tokenID)public view returns(uint256){
    //     return auctions[tokenID].nftHighestBid;
    // }

    // function getMinPrice(uint256 tokenID)external view returns(uint256){
    //     return auctions[tokenID].minPrice;
    // }

    function onAuction(uint256 tokenID)external view returns(bool){
        return hashimaOnAction[tokenID];
    }
}