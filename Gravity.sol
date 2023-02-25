// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IHashima.sol";


/**
Liquid gravity smart contract by Aaron Tolentino
 */
contract Gravity is Ownable,ReentrancyGuard{
    // libreria contador
    using Counters for Counters.Counter;

    // Contador interno
    Counters.Counter private IDs;

    constructor(){
        isMember[msg.sender]=true;
        isGenesis[msg.sender]=true;
        // BLOCK_TOLERANCE=block_tolerance;
    }

    uint256 SELL_TARGET=2;
    
    uint256 MIN_PRICE=5*10**17 wei;

    // ________________Genesis_______________________
    mapping(address=>bool) isGenesis;
    //Acumulado de los lideres si alcanzan el objetivo
    mapping(address=>uint256) genesisReward;
    // ________________Genesis_______________________

    //Contador del total de los miembros
    mapping(address=>uint256) COUNTER;

        //Lista de todos los que interactuan con el contrato
    mapping(address=>bool) internal isMember;
    //Balance de los miembros
    mapping(address=>uint256) memberBalance;

    //Balance del total acumulado por el admin 
    //Son las ganancias seguras del contrato
    uint256 private BOVEDA;
    
    mapping(address=>uint256) checkPoint;
    mapping(address=>address) REFERALS;

    event Start(uint256 tolerance,uint256 timing);

    /**Main function of the contract
    Payment logic
    */
    function payment(address _ID,uint256 _value)external onlyOwner{
        //referal ID has to be a member
        require(isMember[_ID],'referal has to be member');

        //Si el usuario que compra no es miembro, hacerlo.
        if(!isMember[msg.sender]){
            isMember[msg.sender]=true;
            REFERALS[msg.sender]=_ID;
           
        }        

        if(isGenesis[_ID]){
            //Proceso si el referido es un Genesis--------------------GENESIS--------------
            //°Se guarda el 40% del pago
            //°Se guarda el 15% directo al Genesis

            //Propiedad del Genesis actual 15%
            memberBalance[_ID]=memberBalance[_ID]+(_value/100)*15;

            //Actualizo el acumulado de rewards a un 30%
            genesisReward[_ID]=genesisReward[_ID]+(_value/100)*25;
            
            //if account is a Genesis,the amount for BOVEDA is 60%
            BOVEDA=BOVEDA+(_value/100)*60;
            
        }else{
            //member ID is not a Genisis
            //Un miembro tiene un referido si o si

            //La ganancia asegurada aqui es del 88
            BOVEDA=BOVEDA+(_value/100)*88;
            
            //Le doy el 10% al ID del referido
            memberBalance[_ID]+=(_value/100)*10;

        }

        //update counter
        COUNTER[_ID]=COUNTER[_ID]+1;

        //Agrego el 2% al que refirio al referido
        memberBalance[REFERALS[_ID]]+=(_value/100)*2;
    }    


    // init the Hashima protocol inside this smart contract
    function init(address hashima_contrac)external onlyOwner returns(uint256){
        (uint256 _blockNumber,uint256 _timing)=IHashima(hashima_contrac).init();
        emit Start(_blockNumber,_timing);
        return _blockNumber;

    }

    //Solo el administrador del contrato puede definir nuevos 'lideres'
    function createGenesis(address new_genesis)public onlyOwner{
        // address is not a member. Admin becomes the Reference
        if(!isMember[new_genesis]){
            isMember[new_genesis]=true;
            REFERALS[new_genesis]=msg.sender;
        }        
        isGenesis[new_genesis]=true;
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
        address hashima_contract,
        uint256 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
        )external onlyOwner{

        uint256 ID=IHashima(hashima_contract).mintFor(
            _stars, 
            _uri,
            _nonce, 
            _price, 
            _forSale, 
            _receiver
        );
        emit New(ID);

    }

    function getIsMember(address _member)external view returns(bool){
        return isMember[_member];
    }

    // is the address a genesis member of this smart contract?
    function getIsGenesis(address _leader)external view returns(bool){
        return isGenesis[_leader];
    }

    
    //Genesis member withdraw 
    function withdrawGenesis()external nonReentrant{
        require(isGenesis[msg.sender],'has to be Genesis');
        require(memberBalance[msg.sender]>0,'leader balance cannot be 0');
        // require(checkPoint[msg.sender]+BLOCK_TOLERANCE<block.number,'not the time yet');
        uint256 totalAmount=memberBalance[msg.sender];
        
        //If Genesis reach 'SELL_TARGET' increase amount
        if(COUNTER[msg.sender]>SELL_TARGET){
            totalAmount=totalAmount+genesisReward[msg.sender];
        }
        // require(totalAmount<address(this).balance);

        (bool sent, ) = msg.sender.call{value:totalAmount}("");
        require(sent,"Fail in the withdraw");
        //Si el pago es exitoso, actualizar todos los balances.
        // Update BOVEDA balance if SELL_TARGET is not reached
        if(COUNTER[msg.sender]<SELL_TARGET)BOVEDA+=genesisReward[msg.sender];
        //Reiniciar el contador(solo aplica a lideres)
        COUNTER[msg.sender]=0;
        //Reiniciar el balance general
        memberBalance[msg.sender]=0;
        //Reiniciar el balance de las hipoteticas ganancias
        genesisReward[msg.sender]=0;

        // checkPoint[msg.sender]=block.number;

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

    function getGenesisReward(address _address)external view returns(uint256){
        return genesisReward[_address];  
    }

    function getReferal(address _address)external view returns(address){
        return REFERALS[_address];  
    }


    function getCounter(address _account)public view returns(uint256){
        return COUNTER[_account];
    }

}