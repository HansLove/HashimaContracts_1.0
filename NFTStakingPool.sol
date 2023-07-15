// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Nakamoto.sol";
import "./IHashima.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract NFTStakingPool{

    Nakamoto NakamotoNFTContract;

    function deposit() external payable {}

    // Struct to represent an individual staker
    struct Staker {
        address owner; // owner of Hashima
        uint256 lastUpdateTime; // timestamp of the user's last update
        bool active;
    }

    constructor(Nakamoto _contract){
        NakamotoNFTContract=_contract;
    }

    uint256 constant private TOTAL_NFT_SUPPLY = 21000; // total supply of Nakamoto NFTs
    uint256 constant private REWARD_RATE = 10; // reward rate per block (in wei)
    uint256 constant private BLOCK_TIME = 3; // block time in seconds


    mapping(uint256 => Staker) public stakers; // mapping of staker addresses to Staker structs
    uint256 public totalStaked; // total amount of Nakamoto staked in the pool

    // Function to stake Nakamoto NFTs
    function stake(uint256 hashima_id) external {
        require(IERC721(NakamotoNFTContract).ownerOf(hashima_id)==msg.sender);
        Staker storage _staker = stakers[hashima_id];

        // require(!_staker.active,'active');

        // Transfer Nakamoto NFTs from user to contract
        IERC721(NakamotoNFTContract).transferFrom(msg.sender, address(this), hashima_id);

        // Update the staker's balance and last update time
        _staker.owner=msg.sender;
        _staker.lastUpdateTime = block.number;
        _staker.active = true;

        // Update the total staked amount
        totalStaked += 1;
    }

    // Function to unstake Nakamoto NFTs
    function unstake(uint256 hashima_id) external {
        require(hashima_id > 0);
        Staker storage st = stakers[hashima_id];

        // Ensure that the staker has enough balance to unstake
        require(st.owner==msg.sender, "only owner");

        // Calculate the amount of rewards to distribute to the user
        uint256 rewards = getRewards(hashima_id);

        require(address(this).balance >= rewards, "Insufficient contract balance to distribute rewards");
        // Transfer the user's Nakamoto and rewards to them
        NakamotoNFTContract.transferFrom(address(this),msg.sender,hashima_id);
        
        // Send money to user
        payable(msg.sender).transfer(rewards);

        // Update the staker's balance and last update time
        st.owner = address(0);
        st.active =false;

        // Update the total staked amount
        totalStaked -= 1;
    }

    // Function to calculate the amount of rewards to distribute to a staker
    function getRewards(uint256 hashima_id) public view returns (uint256) {
        Staker storage st = stakers[hashima_id];
        uint256 elapsedBlocks = (block.number - st.lastUpdateTime);
        uint256 rewardAmount = REWARD_RATE * elapsedBlocks;
        uint256 rewardRatio = rewardAmount / totalStaked;
        uint256 contractBalance = address(this).balance;
        uint256 stakerRewards = contractBalance * rewardRatio;
        //return contractBalance;
        return stakerRewards;
    }

}
