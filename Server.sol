// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Nakamoto.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Server is Ownable,ReentrancyGuard{

    Nakamoto hashimaContract;
    
    constructor(Nakamoto hashima_contract){
        hashimaContract=hashima_contract;
        //Establecemos primer admin
        ADMIN[msg.sender]=true;
    
    }

    // Rastrear que cuentas han pagado su emision con el contrato
    mapping(address=>bool) debt;

    // Lista de administradores
    mapping(address=>bool) ADMIN
    ;
    uint256 minPrice=0.1 ether;

    function payServer()external payable{
        require(msg.value>=minPrice,'min price no reach');

        debt[msg.sender]=true;
    }

    //Esta funciona la llama el servidor para ver si el usuario pago su Hashima
    //devuelve si pago y cuantas estrellas junto con la URI
    function setAmin(address _user)external onlyOwner{
        ADMIN[_user]=!ADMIN[_user];
    }

    //Generar un nuevo administrador
    function checkPayment(address _user)public view returns(bool){
        return debt[_user];
    }

    modifier isAdmin(){
        require(ADMIN[msg.sender],'not admin');
        _;
    }

    event Start(uint256 tolerance);

    function Init()external isAdmin returns(uint256){
        uint256 _blockNumber=hashimaContract.Init();
        emit Start(_blockNumber);
        return _blockNumber;

    }

    event New(uint256 _id);
        
    //cuando el servidor tenga listo el hashima lo deposita
    function mint(
        uint256 _stars,
        string memory _data,
        string memory _nonce,
        string memory _uri,
        uint256 _price,
        bool _forSale,
        address _receiver
        )external isAdmin nonReentrant{

        require(debt[_receiver],'user no pay');

        uint256 ID=hashimaContract.MintFor(
            _stars, 
            _data,
            _nonce, 
            _uri, 
            _price, 
            _forSale, 
            _receiver
        );
        debt[_receiver]=false;
        emit New(ID);

    }
    
    //Funcion para que el dueño cambie el precio
    function setMinPrice(uint256 _minPrice)public onlyOwner{
        require(_minPrice>0);
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