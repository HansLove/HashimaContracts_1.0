// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IHashima.sol";

contract Multisig {

    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );
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

        numConfirmationsRequired = _numConfirmationsRequired;
        
    }

    event Init(uint256, uint256);

    // 1. Pay to server
    function payServer()external payable{
        require(msg.value>=PRICE,'min price no reach');
        require(!debt[msg.sender],'already paid');
        debt[msg.sender]=true;
    }

    // 2. Multisig llama a init() del servidor
    function init(address hashima_contract)external onlyOwner returns(uint256,uint256){
        (uint256 _blockNumber,uint256 _timing)=IHashima(hashima_contract).init();
        emit Init(_blockNumber,_timing);
        return (_blockNumber,_timing);
    }

    uint256 PRICE=0.1 ether;


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

        // uint256 ID=
        IHashima(hashima_contract).mintFor(
            _stars, 
            _uri,
            _nonce, 
            _price, 
            _forSale, 
            _receiver
        );
        // Hashima minted, now is false
        debt[_receiver]=false;

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

}
