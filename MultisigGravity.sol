// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IHashima.sol";
import "./Gravity.sol";


contract MultisigGravity{

    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    mapping(address=>bool) debt;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    //Lista de todos los que interactuan con el contrato
    mapping(address=>bool) internal isMember;
    //Balance de los miembros
    mapping(address=>uint256) memberBalance;

    // ________________Genesis_______________________
    mapping(address=>bool) isGenesis;
    //Acumulado de los lideres si alcanzan el objetivo

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }


    // Constructor
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        // Smart contract genera un sistema gravity.
        isMember[msg.sender]=true;
        isMember[address(this)]=true;
        numConfirmationsRequired = _numConfirmationsRequired;
        
    }

    mapping(address=>address) REFERALS;

    uint256 private BOVEDA;

    mapping(address=>uint256) COUNTER;

    uint256 PRICE=0.1 ether;

    // 1. Pay to server
    function pay(address _ID)external payable{
        //referal ID has to be a member
        uint256 _value=msg.value;
        require(PRICE==_value,'incorrect price');
        require(isMember[_ID],'referal has to be member');

        //Si el usuario que compra no es miembro, hacerlo.
        if(!isMember[msg.sender]){
            isMember[msg.sender]=true;
            REFERALS[msg.sender]=_ID;
           
        }        

        if(isGenesis[_ID]){
            //Proceso si el referido es un Genesis--------------------GENESIS--------------
            //°Se guarda el 20% directo al Genesis

            //Propiedad del Genesis actual 15%
            memberBalance[_ID]=memberBalance[_ID]+(_value/100)*15;

            //if account is a Genesis,the amount for BOVEDA is 83%
            BOVEDA=BOVEDA+(_value/100)*83;
            
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

        //Agrego el 2% al que refirio gravity
        memberBalance[REFERALS[_ID]]+=(_value/100)*2;

        debt[msg.sender]=true;
    }   

    event Init(uint256, uint256);
    event New(uint256 _id);


    // 2. Multisig llama a init() de la privkey del servidor.
    function init(address hashima_contract)external onlyOwner returns(uint256,uint256){
        (uint256 _blockNumber,uint256 _timing)=IHashima(hashima_contract).init();
        emit Init(_blockNumber,_timing);
        return (_blockNumber,_timing);
    }

    modifier checkMintingData(string memory _data,uint256 _stars,uint256 _price){
        require(bytes(_data).length >= 1, "Data must be at least 1 byte long");
        require(msg.sender != address(0));
        require(_stars>0,"At least 1 star");
        require(_price>0,"Price cannot be 0");
        _;
    }      

    //3. Minar Hashima
    function mint(
        address hashima_contract,
        uint256 _stars,
        string memory _uri,
        string memory _nonce,
        uint256 _price,
        bool _forSale,
        address _receiver
        )external checkMintingData(_uri,_stars,_price) onlyOwner{

        require(debt[_receiver],'user no pay');

        uint256 _id=IHashima(hashima_contract).mintFor(
            _stars, 
            _uri,
            _nonce, 
            _price, 
            _forSale, 
            _receiver
        );

        // Hashima minted, now is false
        debt[_receiver]=false;
        emit New(_id);

    }

    receive() external payable {
        // emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function getPrice()external view returns(uint256){
        return PRICE;
    }

    // Generar solicitud de retiro
    function submitTransaction(
        address _to,
        uint _value
        ) public onlyOwner {

        uint txIndex = transactions.length;

        uint256 totalAmount=address(this).balance;
        require(totalAmount>=_value,'incorrect value');

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value);
    }

    // Los socios llaman a la funcion para dar permiso a retirar los fondos
    function confirmTransaction(uint _txIndex)public onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex){

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;


        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // Si se tienen las confirmaciones necesarias, ejecutar transaccion
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex){

        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;
        
        // Retiro del servidor los fondos
        (bool success, ) = transaction.to.call{value: transaction.value}("");

        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // Socio retira su permiso de la transaccion
    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)public view
        returns (
            address to,
            uint value,
            bool executed,
            uint numConfirmations
        ){
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function checkPayment(address _user)public view returns(bool){
        return debt[_user];
    }


    function getIsMember(address _member)external view returns(bool){
        return isMember[_member];
    }

    // is the address a genesis member of this smart contract?
    function getIsGenesis(address _leader)external view returns(bool){
        return isGenesis[_leader];
    }

    
    //Genesis member withdraw 
    function withdrawGenesis()external{
        require(isGenesis[msg.sender],'has to be Genesis');
        require(memberBalance[msg.sender]>0,'leader balance cannot be 0');
        // require(checkPoint[msg.sender]+BLOCK_TOLERANCE<block.number,'not the time yet');
        uint256 totalAmount=memberBalance[msg.sender];
        
        (bool sent, ) = msg.sender.call{value:totalAmount}("");
        require(sent,"Fail in the withdraw");
        //Si el pago es exitoso, actualizar todos los balances.

        //Reiniciar el balance general
        memberBalance[msg.sender]=0;

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
    function withdraw() external{
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

}
