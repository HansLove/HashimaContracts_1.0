// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IHashima.sol";
import "./Multisig.sol";

/**
 * Liquid gravity smart contract by Aaron Tolentino
 */
contract Gravity is Ownable, ReentrancyGuard, Multisig {
    using Counters for Counters.Counter;

    Counters.Counter private IDs;
    mapping(address => bool) debt;
    uint256 private BOVEDA;
    mapping(address => uint256) memberBalance;
    uint256 private PRICE = 1 * 10**15 wei;

    mapping(address => bool) isGenesis;
    mapping(address => uint256) COUNTER;
    mapping(address => bool) internal isMember;
    mapping(address => address) REFERALS;

    event Start(uint256 tolerance, uint256 timing);
    event New(uint256 _id);

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired)
        Multisig(_owners, _numConfirmationsRequired)
    {
        isMember[msg.sender] = true;
        isGenesis[msg.sender] = true;
        REFERALS[msg.sender] = msg.sender;
    }

    function pay(address _ID) external payable {
        uint256 _value = msg.value;
        require(_value == PRICE, "Incorrect price");
        require(isMember[_ID], "Referal has to be a member");

        if (!isMember[msg.sender]) {
            isMember[msg.sender] = true;
            REFERALS[msg.sender] = _ID;
        }

        if (isGenesis[_ID]) {
            memberBalance[_ID] += (_value / 100) * 18;
            BOVEDA += (_value / 100) * 80;
        } else {
            BOVEDA += (_value / 100) * 88;
            memberBalance[_ID] += (_value / 100) * 10;
        }

        COUNTER[_ID] += 1;
        memberBalance[REFERALS[_ID]] += (_value / 100) * 2;
        debt[msg.sender] = true;
    }

    function init(address hashima_contract) external onlyAdmin returns (uint256, uint256) {
        (uint256 _randomizer, uint256 _timing) = IHashima(hashima_contract).init();
        emit Init(_randomizer, _timing);
        return (_randomizer, _timing);
    }

    function mint(
        address hashima_contract,
        uint8 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
    ) external onlyAdmin {
        // require(debt[_receiver], "Receiver has no pending payment");

        uint256 ID = IHashima(hashima_contract).mintFor(_stars, _uri, _nonce, _price, _forSale, _receiver);

        if (ID > 0) {
            debt[_receiver] = false;
            emit New(ID);
        }
    }

    function createGenesis(address new_genesis) public onlyOwner {
        if (!isMember[new_genesis]) {
            isMember[new_genesis] = true;
            REFERALS[new_genesis] = msg.sender;
        }
        isGenesis[new_genesis] = true;
    }


    function withdraw() external nonReentrant {
        uint256 total_balance = memberBalance[msg.sender];
        require(total_balance > 0, "Balance is 0");

        (bool sent, ) = msg.sender.call{ value: total_balance }("");
        require(sent, "Failed to send funds to member");
        memberBalance[msg.sender] = 0;
    }

    function becomeGenesis() external {
        require(!isGenesis[msg.sender], "Already a genesis");
        require(COUNTER[msg.sender] > 100, "Counter should be greater than 100");
        isGenesis[msg.sender] = true;
    }

    function getReferal(address _address) external view returns (address) {
        return REFERALS[_address];
    }

    function checkPayment(address _address) external view returns (bool) {
        return debt[_address];
    }

    function getCounter(address _account) public view returns (uint256) {
        return COUNTER[_account];
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function getPrice() external view returns (uint256) {
        return PRICE;
    }

    function getIsMember(address _member) external view returns (bool) {
        return isMember[_member];
    }

    function getIsGenesis(address _leader) external view returns (bool) {
        return isGenesis[_leader];
    }

    function getMemberBalance(address _address) external view returns (uint256) {
        return memberBalance[_address];
    }
}
