// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Hashima.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Server is Ownable,ReentrancyGuard{

    Hashima hashimaContract;
    
    constructor(Hashima hashima_contract){
        hashimaContract=hashima_contract;
    
    }

    mapping(address=>bool) debt;
    uint256 minPrice=0.1 ether;

    function payServer()external payable{
        require(msg.value>=minPrice,'min price no reach');

        debt[msg.sender]=true;
    }

    //Esta funciona la llama el servidor para ver si el usuario pago su Hashima
    //devuelve si pago y cuantas estrellas junto con la URI
    function checkPayment(address _user)public view returns(bool){
        return debt[_user];
    }

    function Init()external returns(uint256){
        uint256 _blockNumber=hashimaContract.Init();
        return _blockNumber;
    }

    //cuando el servidor tenga listo el hashima lo deposita
    function mint(
        uint256 _stars,
        string memory _data,
        string memory _nonce,
        string memory _uri,
        uint256 _price,
        bool _forSale,
        address _receiver
        )external nonReentrant{

        require(debt[_receiver],'user no pay');

        hashimaContract.MintFor(
            _stars, 
            _data,
            _nonce, 
            _uri, 
            _price, 
            _forSale, 
            _receiver
        );
        debt[_receiver]=false;
    }
    
    //Funcion para que el dueño cambie el precio
    function setMinPrice(uint256 _minPrice)public onlyOwner{
        minPrice=_minPrice;
    }

    function getPrice()external view returns(uint256){
        return minPrice;
    }

    function withdraw(address _receiver)public onlyOwner{
        uint256 totalAmount=address(this).balance;
        (bool sent, ) = _receiver.call{value:totalAmount}("");
        require(sent,"No cool withdraw");
    }

}