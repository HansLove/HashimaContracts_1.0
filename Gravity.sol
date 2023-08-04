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
    // El usuario pago?
    mapping(address => bool) debt;
    // Guarda las ganancias 
    uint256 private BOVEDA;

    mapping(address => uint256) memberBalance;

    // Precio de minado
    uint256 private PRICE = 1 * 10**17 wei;

    // Cuantas conexiones ha hecho
    mapping(address => uint256) COUNTER;
    mapping(address => bool) internal isMember;
    mapping(address => address) REFERALS;

    event Start(uint256 tolerance, uint256 timing);
    event New(uint256 _id);

    IHashima hashimaContract;

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired,IHashima _hashima)
        Multisig(_owners, _numConfirmationsRequired)
    {
        isMember[msg.sender] = true;
        REFERALS[msg.sender] = msg.sender;
        hashimaContract=_hashima;
    }

    function pay(address _ID) external payable {
        uint256 _value = msg.value;
        require(_value == PRICE, "Incorrect price");
        require(isMember[_ID]||hashimaContract.balanceOf(_ID)>0, "Referal has to be a member");

        if (!isMember[msg.sender]) {
            isMember[msg.sender] = true;
            REFERALS[msg.sender] = _ID;
        }

        if ( COUNTER[_ID]>100) {
            memberBalance[_ID] += (_value / 100) * 18;
            BOVEDA += (_value / 100) * 80;
        } else if( COUNTER[_ID]>200){
            memberBalance[_ID] += (_value / 100) * 18;
            BOVEDA += (_value / 100) * 80;
        }else{
            memberBalance[_ID] += (_value / 100) * 10;
            BOVEDA += (_value / 100) * 88;

        }

        //Aumentar contador
        COUNTER[_ID] += 1;
        //El referido del referido se queda con el 2%
        memberBalance[REFERALS[_ID]] += (_value / 100) * 2;
        debt[msg.sender] = true;
    }

    function init() external onlyAdmin returns (uint256, uint256) {
        (uint256 _randomizer, uint256 _timing) = IHashima(hashimaContract).init();
        emit Init(_randomizer, _timing);
        return (_randomizer, _timing);
    }

    function mint(
        uint8 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver) external onlyAdmin {
        // require(debt[_receiver], "Receiver has no pending payment");

        uint256 ID = IHashima(hashimaContract).mintFor(_stars, _uri, _nonce, _price, _forSale, _receiver);

        if (ID > 0) {
            debt[_receiver] = false;
            emit New(ID);
        }
    }

    function withdraw() external nonReentrant {
        uint256 total_balance = memberBalance[msg.sender];
        require(total_balance > 0, "Balance is 0");

        (bool sent, ) = msg.sender.call{ value: total_balance }("");
        require(sent, "Failed to send funds to member");
        memberBalance[msg.sender] = 0;
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

    function giveMembership(address new_member) external onlyOwner {
        require(!isMember[new_member]);
        isMember[new_member]=true;
        REFERALS[new_member] = msg.sender;
        
    }

    function getPrice() external view returns (uint256) {
        return PRICE;
    }

    function getIsMember(address _member) external view returns (bool) {
        return isMember[_member];
    }

    function getMemberBalance(address _address) external view returns (uint256) {
        return memberBalance[_address];
    }
}
