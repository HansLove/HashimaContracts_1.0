// // SPDX-License-Identifier: MIT
// pragma solidity >=0.4.22 <0.9.0;

// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "./IHashima.sol";

// contract HashimaMarket is IERC721Receiver {

//     using Counters for Counters.Counter;
//     Counters.Counter private _tokenIds;

//     mapping (address => mapping(uint256=>TokenMeta)) private _tokenMeta;
//     mapping (address => mapping(address=>mapping(uint256=>bool))) private OWNERS;
 

//     struct TokenMeta {
//         address hashima_contract;
//         uint256 id;
//         uint256 price;
//         string name;
//         string uri;
//         bool sale;
//     }
    
//     function onERC721Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes calldata data
//     ) external returns (bytes4){

//     }

//     function aprovar(address hashima_contract,uint256 tokenId)private{
//         IHashima(hashima_contract).approve(address(this), tokenId);
//     }

//     function deposit(address hashima_contract,uint256 tokenId) external{
//         require (msg.sender ==  IHashima(hashima_contract).ownerOf(tokenId), 'Sender must be owner');
//         aprovar(hashima_contract, tokenId);
//         //El hashima es transferido a este contrato
//         IHashima(hashima_contract).transferFrom(msg.sender, address(this), tokenId);
//         OWNERS[hashima_contract][msg.sender][tokenId]=true;
        
        
//    }


//     /**
//      * @dev sets maps token to its price
//      * @param _tokenId uint256 token ID (token number)
//      * @param _sale bool token on sale
//      * @param _price unit256 token price
//      * 
//      * Requirements: 
//      * `tokenId` must exist
//      * `price` must be more than 0
//      * `owner` must the msg.owner
//      */
//     function setHashimaSale(
//         address hashima_contract,
//         uint256 _tokenId, 
//         bool _sale, 
//         uint256 _price) public {

//         require(_price > 0);
//         require(OWNERS[hashima_contract][msg.sender][_tokenId],'only the original owner');

//         _tokenMeta[hashima_contract][_tokenId].sale = _sale;
//         setTokenPrice(hashima_contract,_tokenId, _price);
//     }

//     function setTokenPrice(address hashima_contract,uint256 _tokenId, uint256 _price) public {
//         require(IHashima(hashima_contract).ownerOf(_tokenId) == msg.sender);
//         _tokenMeta[hashima_contract][_tokenId].price = _price;
        
//     }

//     function hashimaPrice(address hashima_contract,uint256 tokenId) public view returns (uint256) {
//         return _tokenMeta[hashima_contract][tokenId].price;
        
//     }


//     function tokenMeta(address hashima_contract,uint256 _tokenId) public view returns (TokenMeta memory) {
//         return _tokenMeta[hashima_contract][_tokenId];
//     }

 
//     function purchaseToken(address hashima_contract,uint256 _tokenId) public payable {
//         require(msg.value >= _tokenMeta[hashima_contract][_tokenId].price);
//         address tokenSeller =IHashima(hashima_contract).ownerOf(_tokenId);

//         payable(tokenSeller).transfer(msg.value);

//         IHashima(hashima_contract).transferFrom(tokenSeller, msg.sender, _tokenId);
//         _tokenMeta[hashima_contract][_tokenId].sale = false;
//     }

    
// }