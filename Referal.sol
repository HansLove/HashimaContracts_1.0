// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Nakamoto.sol";


contract Referal is Ownable{
    // libreria contador
    using Counters for Counters.Counter;

    // Contador interno
    Counters.Counter private IDs;

    Nakamoto hashimaContract;

    constructor(Nakamoto hashima_contract){
        hashimaContract=hashima_contract;
        // referencia de tiempo
        checkPoint[msg.sender]=block.number;
        //generar el primer admin de este contrato
        ADMIN[msg.sender]=true;

    }

    // ________________lider_____________________
    mapping(address=>bool) isLeader;
    //Acumulado de los lideres
    mapping(address=>uint256) leaderBalance;
    //Acumulado de los lideres si alcanzan el objetivo
    mapping(address=>uint256) leaderBalanceReward;
    //Contador del total de los lideres
    mapping(address=>uint256) leaderCounter;
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

    event Start(uint256 tolerance,uint256 timing);

    // Init the Hashima protocol
    function Init()external isAdmin returns(uint256){
        (uint256 _blockNumber,uint256 _timing)=hashimaContract.Init();
        emit Start(_blockNumber,_timing);
        return _blockNumber;

    }

    /**Main function 
    Funcion que se encarga del sistema de pago
    */
    function payment(address _ID)public payable{
        require(msg.value>=MIN_PRICE,'not the correct price');
        require(isMember[_ID],'referal has to be member');
        //El referido tiene que ser miembro
        uint256 _value=msg.value;

        //Si el usuario que compra no es miembro, hacerlo.
        if(!isMember[msg.sender]){
            isMember[msg.sender]=true;
            REFERALS[msg.sender]=_ID;
            checkPoint[msg.sender]=block.number;
           
        }        

        if(isLeader[_ID]){
            //Proceso si el referido es un lider--------------------LIDER--------------
            //°Se guarda el 40% del pago
            //°Se guarda el 10% directo al referido

            //10% ya es propiedad del lider
            leaderBalance[_ID]=leaderBalance[_ID]+(_value/100)*10;
            //Actualizo el acumulado de rewards a un 30%
            leaderBalanceReward[_ID]=leaderBalanceReward[_ID]+(_value/100)*30;

            //Sumo 1 al contador del lider
            leaderCounter[_ID]+=1;
            
            //Si es lider, la cantidad ganada es 60% porque el otro
            //no es ganancia asegurada para el admin
            BOVEDA=BOVEDA+(_value/100)*60;
            
            //Los lideres si llevan un conteo, los miembros no.
            //Si el lider alcanza 100 ventas, se gana el 40% de la venta.
            leaderBalance[_ID]+=1;
            
        }else{
            //El ID entregado no es un lider
            //Un miembro tiene un referido si o si

            //La ganancia asegurada aqui es del 88
            BOVEDA=BOVEDA+(_value/100)*88;
            
            //Agrego el 2% al que refirio al referido
            memberBalance[REFERALS[_ID]]+=(_value/100)*2;

            //Le doy el 10% al ID del referido
            memberBalance[_ID]+=(_value/100)*10;

        }
        //Mint del token
        debt[msg.sender]=true;
    }


    //Cuanto tiempo tiene que pasar hasta que los usuarios 
    //puedan sacar el dinero final
    uint256 MONTH=864000;
    uint256 public POINT=0;

    uint256 SELL_TARGET=99;
    
    uint256 MIN_PRICE=5*10**17 wei;

    modifier isAdmin(){
        require(ADMIN[msg.sender],'not admin');
        _;
    }

        //Solo el administrador del contrato puede definir nuevos 'lideres'
    function createLeader(address _newLider)public onlyOwner{
        isLeader[_newLider]=true;
        isMember[_newLider]=true;
        checkPoint[msg.sender]=block.number;
    }

    event New(uint256 _id);

    event Referal1(bool exito);

    ///SETTERS
    function setPrice(uint256 _newPrice)external onlyOwner{
        MIN_PRICE=_newPrice;
    }

    function getPrice()external view returns(uint256){
        return MIN_PRICE;
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
        )external isAdmin{

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

    function getIsMember(address _member)external view returns(bool){
        return isMember[_member];
    }

    function getIsLeader(address _leader)external view returns(bool){
        return isLeader[_leader];
    }

    //----- Retiros ----------------------------------------------------------
    modifier checkTime(){
        require(block.number>checkPoint[msg.sender]+MONTH,'Not the time yet');
        _;
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
    function withdraw()checkTime external{
        require(checkPoint[msg.sender]+MONTH<block.number,'Not the time yet');
        uint256 _balance=memberBalance[msg.sender];
        require(_balance>0,'balance is 0');
        (bool sent, ) = msg.sender.call{value:_balance}("");
        require(sent,"No cool withdraw to member");
        memberBalance[msg.sender]=0;
        checkPoint[msg.sender]=block.number;

    }

    function getMemberBalance(address _address)external view returns(uint256){
        return memberBalance[_address];  
    }

    function getLeaderBalance(address _address)external view returns(uint256){
        return leaderBalance[_address];  
    }
    function getReferal(address _address)external view returns(address){
        return REFERALS[_address];  
    }

    function getCheckPoint(address _address)external view returns(uint256){
        return (checkPoint[_address]+MONTH)-block.number;  
    }

    function checkPayment(address _user)public view returns(bool){
        return debt[_user];
    }

}