// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ProofOfWork {
    uint256 public difficulty;
    uint256 public maxGas=100000;

    event SolutionFound(uint256 nonce);

    constructor(uint256 _difficulty, uint256 _maxGas) {
        difficulty = _difficulty;
        maxGas = _maxGas;
    }

    function proofOfWork(uint256 nonce) public {
        require(block.gaslimit <= maxGas, "Gas limit exceeded");
        bytes32 hash = sha256(abi.encodePacked(nonce));
        require(uint256(hash) < 2**difficulty, "Invalid nonce");
        emit SolutionFound(nonce);
    }


    function checkProofOfWork(uint256 nonce, bytes32 hash, uint _difficulty) public pure returns (bool) {
        bytes32 target = bytes32(uint256(2)**(256-_difficulty));
        bytes32 resultHash = sha256(abi.encodePacked(nonce, hash));
        return (resultHash <= target);
}

}
