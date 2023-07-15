// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IHashima.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Server is Ownable,ReentrancyGuard{
        
    constructor(){
        //Establecemos primer admin
        ADMIN[msg.sender]=true;
    
    }

    // Rastrear que cuentas han pagado su emision con el contrato
    mapping(address=>bool) debt;

    // Lista de administradores
    mapping(address=>bool) ADMIN;
    
    uint256 PRICE=0.1 ether;

    function payServer()external payable nonReentrant{
        require(msg.value>=PRICE,'min price no reach');
        require(!debt[msg.sender],'already paid');
        debt[msg.sender]=true;
    }
    
    // Admin change the status of an account
    function setAmin(address _user)external onlyOwner{
        ADMIN[_user]=!ADMIN[_user];
    }


    //Esta funciona la llama el servidor para ver si el usuario pago su Hashima
    //devuelve si pago y cuantas estrellas junto con la URI
    function checkPayment(address _user)external view returns(bool){
        return debt[_user];
    }

    modifier isAdmin(){
        require(ADMIN[msg.sender],'not admin');
        _;
    }

    event Start(uint256 tolerance,uint256 timing);

    /**@dev only the admin can  init the protocol*/
    // function Init(address hashima_contract)external isAdmin returns(uint256,uint256){
    //     (uint256 _blockNumber,uint256 _timing)=IHashima(hashima_contract).init();
    //     emit Start(_blockNumber,_timing);
    //     return (_blockNumber,_timing);

    // }

    event New(uint256 _id);
        
    modifier checkMintingData(string memory _data,uint256 _stars,uint256 _price){
        require(bytes(_data).length >= 1, "Data must be at least 1 byte long");
        require(msg.sender != address(0));
        require(_stars>0,"At least 1 star");
        require(_price>0,"Price cannot be 0");
        _;
    }      

    //cuando el servidor tenga listo el hashima lo deposita
    function mint(
        address hashima_contract,
        uint8 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
        )external checkMintingData(_uri,_stars,_price) isAdmin{

        require(debt[_receiver],'user no pay');

        uint256 ID=IHashima(hashima_contract).mintFor(
            _stars, 
            _uri,
            _nonce, 
            _price, 
            _forSale, 
            _receiver
        );
        // Hashima minted, now is false
        debt[_receiver]=false;
        emit New(ID);

    }
    
    //Owner can change the minting price for mining service
    function setMinPrice(uint256 _PRICE)external onlyOwner{
        require(_PRICE>0,'price cannot be 0');
        PRICE=_PRICE;
    }


    function getPrice()external view returns(uint256){
        return PRICE;
    }

    function withdraw(address _receiver)external onlyOwner returns(bool){
        uint256 totalAmount=address(this).balance;
        require(totalAmount>0);
        (bool sent, ) = _receiver.call{value:totalAmount}("");
        require(sent,"No cool withdraw");
        return sent;
    }

}