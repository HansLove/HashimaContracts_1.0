// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Nakamoto.sol";
import "./IHashima.sol";


/**
LG2, liquid gravity focus on init Hashima
 */
contract LG2 is Ownable,ReentrancyGuard{
    // libreria contador
    using Counters for Counters.Counter;

    // Contador interno
    Counters.Counter private IDs;

    IHashima private hashimaContract;

    constructor(IHashima _hashimaContractAddress){
        //generar el primer admin de este contrato
        ADMIN[msg.sender]=true;
        isMember[msg.sender]=true;
        hashimaContract = IHashima(_hashimaContractAddress);
        REFERALS[msg.sender]=msg.sender;
    }

    uint256 SELL_TARGET=2;
    
    uint256 MIN_PRICE=5*10**17 wei;

    modifier isAdmin(){
        require(ADMIN[msg.sender],'not admin');
        _;
    }

    //Contador del total de los miembros
    mapping(address=>uint256) COUNTER;

    // Lista de administradores
    mapping(address=>bool) ADMIN;

    // Rastrear que cuentas han pagado su emision con el contrato
    mapping(address=>bool) debt;
    // ___________________-
        //Lista de todos los que interactuan con el contrato
    mapping(address=>bool) isMember;
    //Balance de los miembros
    mapping(address=>uint256) memberBalance;

    //Balance del total acumulado por el admin 
    //Son las ganancias seguras del contrato
    uint256 private BOVEDA;
    
    mapping(address=>uint256) checkPoint;
    mapping(address=>address) REFERALS;

    event Init(uint256 tolerance,uint256 timing);


    event New(uint256 _id);
    event Referal1(bool exito);


    function init(address _ID)external nonReentrant payable {
        // reach the value
        require(msg.value>=MIN_PRICE,'not the correct price');
        //referal ID has to be a member
        require(isMember[_ID],'referal has to be member');

        uint256 _value=msg.value;
        //Si el usuario que compra no es miembro, hacerlo.
        if(!isMember[msg.sender]){
            isMember[msg.sender]=true;
            REFERALS[msg.sender]=_ID;
        }        

        //La ganancia asegurada aqui es del 88
        BOVEDA=BOVEDA+(_value/100)*88;
        
        //Le doy el 10% al ID del referido
        memberBalance[_ID]+=(_value/100)*10;

        //update counter
        COUNTER[_ID]=COUNTER[_ID]+1;

        //Agrego el 2% al que refirio al referido
        memberBalance[REFERALS[_ID]]+=(_value/100)*2;

        debt[msg.sender]=true;
        // (uint256 randomizer, uint256 timing) = hashimaContract.init(msg.sender);
        (uint256 randomizer, uint256 timing) = hashimaContract.init();
        // return (randomizer, timing);
        emit Init(randomizer, timing);

    }   

    //cuando el servidor tenga listo el hashima lo deposita
    function mint(
        uint8 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
        )external 
        isAdmin
        {
        
        require(debt[_receiver],'user no pay');

        uint256 ID = hashimaContract.mintFor(_stars, _uri, _nonce, _price, _forSale, _receiver);

        debt[_receiver]=false;
        emit New(ID);

    } 

    ///SETTERS
    function setPrice(uint256 _newPrice)external onlyOwner{
        MIN_PRICE=_newPrice;
    }

    function getPrice()external view returns(uint256){
        return MIN_PRICE;
    }



    function getIsMember(address _member)external view returns(bool){
        return isMember[_member];
    }


    //El administrador retira
    function withdrawAdmin()external onlyOwner{
        require(BOVEDA>0);
        (bool sent, ) = msg.sender.call{value:BOVEDA}("");
        require(sent,"No cool withdraw");
        //Restablecer el valor de la Boveda
        BOVEDA=0;
        
    }

    //Retiro para los miembros
    function withdraw() external nonReentrant{
        uint256 _balance=memberBalance[msg.sender];
        require(_balance>0,'balance is 0');
        (bool sent, ) = msg.sender.call{value:_balance}("");
        require(sent,"No cool withdraw to member");
        memberBalance[msg.sender]=0;
    }

    function getMemberBalance(address _address)external view returns(uint256){
        return memberBalance[_address];  
    }

    function getReferal(address _address)external view returns(address){
        return REFERALS[_address];  
    }

    function checkPayment(address _user)public view returns(bool){
        return debt[_user];
    }

    function getCounter(address _account)public view returns(uint256){
        return COUNTER[_account];
    }

}