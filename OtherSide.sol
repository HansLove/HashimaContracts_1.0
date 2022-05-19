// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import "./Hashi.sol";
import "./IHashima.sol";

contract OtherSide is ERC20Burnable{
    uint256 negative_votes=0;
    uint256 positive_votes=0;

    uint256 current_rate=1;
    uint256 dificultad=1;

    Hashi private hashiContract;

    constructor(Hashi HASHI_contract) ERC20("Petunia", "PETU"){
        hashiContract=HASHI_contract;
        
    }

    event ExchangeComplete(uint256 amount,bool free,bytes32 result_hash);


    function deposit(uint256 amount) public{
        (bool free,bytes32 result_hash)=coldProofOfWork();
        if(!free)hashiContract.burnFrom(msg.sender, amount);

        uint256 amounToMint=amount*current_rate;
        _mint(msg.sender,amounToMint);
        emit ExchangeComplete(amounToMint,free,result_hash);

   }

    //Los usuarios votan la direccion de la tasa de cambio $HASHI/$PETU
    function vote(bool positive,uint256 amount) external{
        burn(amount);
        if(positive){
            positive_votes+=amount;
        }else{
            negative_votes+=amount;
        }
    }


    function restartCycle()internal{
        if(positive_votes>negative_votes){
            current_rate=current_rate+1;
        }else{
            if(current_rate>1)current_rate=current_rate-1;
            
        }
        negative_votes=0;
        positive_votes=0;
    }

    function coldProofOfWork()private view returns(bool,bytes32){
        
      bytes32 _hashFinal=sha256(abi.encodePacked(block.number,msg.sender,Strings.toString(dificultad)));
      bool respuesta=true;

      for (uint256 index = 0; index < dificultad; index++) {
        if (_hashFinal[index]!=0x00) {
                respuesta=false;  
            }
      
      }
      return (respuesta,_hashFinal);
    }


}

