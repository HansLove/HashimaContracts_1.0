// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IHashima.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Server is Ownable{

    mapping(address=>Payment) debt;
    // mapping(address=>mapping(uint256=>bool)) hashimaBalance;

    IHashima hashimaContract;
    address oficialServer;
    
    constructor(IHashima hashima_contract){
        hashimaContract=hashima_contract;
    
    }

    struct Payment{
        uint256 stars;
        string URI;
        bool paid;
    }

    //Modificador
    modifier onlyServer(){
        require(msg.sender==oficialServer,'only server');
        _;
    }
    address [] ACCEPTED_COINS;  
    uint256 minPrice=0.0001 ether;

    function setServer(address _serv)public onlyOwner{
        oficialServer=_serv;
    }

    function payServer(uint256 _stars,string calldata _uri)external payable{
        require(msg.value>=minPrice,'min price no reach');
        require(_stars<5,'no more than 4 stars');

        Payment memory paymentInput=Payment(
            _stars,
            _uri,
            true

        );
        debt[msg.sender]=paymentInput;
    }

    //cuando el servidor tenga listo el hashima lo deposita
    function depositHashima(uint256 tokenId,address clientUser)external{
        require(debt[clientUser].paid,'user no pay');
        hashimaContract.transferFrom(msg.sender, clientUser, tokenId);
        Payment memory newPay=debt[clientUser];
        newPay.paid=false;
        debt[clientUser]=newPay;
    }
    
    //Esta funciona la llama el servidor para ver si el usuario pago su Hashima
    //devuelve si pago y cuantas estrellas junto con la URI
    function checkPayment(address _user)public view returns(bool,uint256,string memory){
        return (debt[_user].paid,debt[_user].stars,debt[_user].URI);
    }

    function claimHashima(uint256 tokenId)public{
        require(debt[msg.sender].paid,'debt is false');
        debt[msg.sender].paid=false;
        hashimaContract.transferFrom(address(this), msg.sender, tokenId);
        
    }

    //Funcion para que el dueño cambie el precio
    function setMinPrice(uint256 _minPrice)public onlyOwner{
        minPrice=_minPrice;
    }



}