// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IHashima.sol";
import "./Multisig.sol";


/**
Liquid gravity smart contract by Aaron Tolentino
 */
contract Gravity is Ownable,ReentrancyGuard,Multisig{
    // libreria contador
    using Counters for Counters.Counter;

    // Contador interno
    Counters.Counter private IDs;

    // Conteo de los pagos por los usuarios
    mapping(address=>bool) debt;

    constructor(address[] memory _owners, uint _numConfirmationsRequired)
    Multisig(_owners,_numConfirmationsRequired){
        isMember[msg.sender]=true;
        isGenesis[msg.sender]=true;
        REFERALS[msg.sender]=msg.sender;

    }
    
    // Floor price
    uint256 PRICE=1*10**17 wei;

    mapping(address=>bool) isGenesis;

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

    /** 1.user pay the contract for the proof of work
    Main function of the contract Payment logic*/
    function pay(address _ID)external payable{
        uint256 _value=msg.value;
        //referal ID has to be a member
        require(_value==PRICE,'incorrect price');
        require(isMember[_ID],'referal has to be member');

        //Si el usuario que compra no es miembro, hacerlo.
        if(!isMember[msg.sender]){
            isMember[msg.sender]=true;
            REFERALS[msg.sender]=_ID;
           
        }        

        if(isGenesis[_ID]){
            //Proceso si el referido es un Genesis--------------------GENESIS--------------

            //Propiedad del Genesis actual 18%
            memberBalance[_ID]=memberBalance[_ID]+(_value/100)*18;

            //if account is a Genesis,the amount for BOVEDA is 80%
            BOVEDA=BOVEDA+(_value/100)*80;
            
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
        debt[msg.sender]=true;

    }    


    /** 2. Servidor admin llama a init()*/
    function init(address hashima_contract)external onlyAdmin returns(uint256,uint256){
        (uint256 _blockNumber,uint256 _timing)=IHashima(hashima_contract).init();
        emit Init(_blockNumber,_timing);
        return (_blockNumber,_timing);
    }

    
    /** 3. servidor mina Hashima*/
    function mint(
        address hashima_contract,
        uint256 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
        )external onlyAdmin{
        
        require(debt[_receiver]);

        uint256 ID=IHashima(hashima_contract).mintFor(
            _stars, 
            _uri,
            _nonce, 
            _price, 
            _forSale, 
            _receiver
        );
        debt[_receiver]=false;
        emit New(ID);

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
        PRICE=_newPrice;
    }

    function getPrice()external view returns(uint256){
        return PRICE;
    }

    function getIsMember(address _member)external view returns(bool){
        return isMember[_member];
    }

    // is the address a genesis member of this smart contract?
    function getIsGenesis(address _leader)external view returns(bool){
        return isGenesis[_leader];
    }


    //El administrador retira
    function withdrawAdmin()external onlyAdmin{
        require(BOVEDA>0);
        (bool sent, ) = msg.sender.call{value:BOVEDA}("");
        require(sent,"No cool withdraw");
        //Restablecer el valor de la Boveda
        BOVEDA=0;
        
    }

    //Retiro para los miembros
    function withdraw() external nonReentrant{
        uint256 total_balance=memberBalance[msg.sender];
        require(total_balance>0,'balance is 0');
        (bool sent, ) = msg.sender.call{value:total_balance}("");
        require(sent,"No cool withdraw to member");
        memberBalance[msg.sender]=0;

    }

    function getMemberBalance(address _address)external view returns(uint256){
        return memberBalance[_address];  
    }

    function becomeGenesis()external{
        require(!isGenesis[msg.sender],'already genesis');
        require(COUNTER[msg.sender]>100);
        isGenesis[msg.sender]=true;
    }

    function getReferal(address _address)external view returns(address){
        return REFERALS[_address];  
    }

    function checkPayment(address _address)external view returns(bool){
        return debt[_address];  
    }

    function getCounter(address _account)public view returns(uint256){
        return COUNTER[_account];
    }

}