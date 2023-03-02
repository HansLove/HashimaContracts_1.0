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


    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyAdmin() {
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


    //1.  Generar solicitud de retiro
    function submitTransaction(
        address _to,
        uint _value
        ) public onlyAdmin {

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
    function confirmTransaction(uint _txIndex)public onlyAdmin
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
        onlyAdmin
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
        onlyAdmin
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
