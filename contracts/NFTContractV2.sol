//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTContract is ERC1155, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 TOKEN_SIZE = 10;
    uint256 COUNT_PER_TOKEN = 2;
    uint256 TOTAL_TOKEN_COOUNT = TOKEN_SIZE * COUNT_PER_TOKEN;

    uint256 PRESALE_COUNT = 5;
    uint256 PUBLIC_SALE_COUNT = 3;
    
    // Minting Prices Per stage
    uint256 _privateSalePrice = 0.0001 ether; 
    uint256 _publicSalePrice = 0.0002 ether; 

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    uint256 private currentSupply = 0; //start index
    string public name;
    string public symbol;
    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {      
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    constructor(string memory uri) ERC1155(uri) {   
        name = "MultiToken";
        symbol = "MTE"; 
    }

    function setBaseUri(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    uint256[] ids;
    uint256[] amounts;
    function testMint() public onlyOwner {        
        ids = [0, 1];
        amounts = [1, 1];
        _mintBatch(msg.sender, ids, amounts, "");
        currentSupply = currentSupply + 2;
    }

    function preSale(uint256 mintCount, bytes32[] calldata merkleProof)
        external
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(_privateSalePrice, mintCount)
    {
        require(mintCount <= PRESALE_COUNT, "Can mint up to 5 NFTs");
        require(currentSupply + mintCount <= TOTAL_TOKEN_COOUNT, "Overflow Max Supply");      
        for(uint i = 0; i < mintCount; i++) {
            uint256 id  = currentSupply % TOKEN_SIZE; 
            _mint(msg.sender, id, 1, "");
            currentSupply = currentSupply + 1;
        }
        
    }

    function publicSale(uint256 mintCount)
        external
        payable
        isCorrectPayment(_publicSalePrice, mintCount)
    {
        require(mintCount <= PUBLIC_SALE_COUNT, "Can mint up to 5 NFTs");
        require(currentSupply + mintCount <= TOTAL_TOKEN_COOUNT, "Overflow Max Supply");
        for(uint i = 0; i < mintCount; i++) {
            uint256 id  = currentSupply % TOKEN_SIZE;
            _mint(msg.sender, id, 1, "");
            currentSupply = currentSupply + 1;        
        }
    }


    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setPrivateSalePrice(uint256 value) external onlyOwner {
        _privateSalePrice = value;
    }

    function getPrivateSalePrice() public view returns (uint256) {
        return _privateSalePrice;
    }

    function setPublicSalePrice(uint256 value) external onlyOwner {
        _publicSalePrice = value;
    }

    function getPublicSalePrice() public view returns (uint256) {
        return _publicSalePrice;
    }
}
