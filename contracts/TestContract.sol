//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";
contract NFTContract is ERC1155, Ownable, ReentrancyGuard {
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 TOKEN_SIZE = 10;
    uint256 COUNT_PER_TOKEN = 40;
    uint256 TOTAL_TOKEN_COOUNT = TOKEN_SIZE * COUNT_PER_TOKEN;

    uint256 PRESALE_COUNT = 5;
    uint256 PUBLIC_SALE_COUNT = 3;
    
    // Minting Prices Per stage
    uint256 _privateSalePrice = 0.0001 ether; 
    uint256 _publicSalePrice = 0.0002 ether; 

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;
    Counters.Counter private _tokenIdTracker;

    uint256 private currentSupply = 1; //start index
    string public name;
    string public symbol;
    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        // console.logBytes32(merkleProof[0]);    
        // console.logBytes32(merkleProof[1]);    
        // console.logBytes32(root);
        // console.logBytes32(keccak256(abi.encodePacked(msg.sender)));        
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

    function preSale(uint256 mintCount) external payable
    {
        require(currentSupply + mintCount <= TOTAL_TOKEN_COOUNT, "Overflow Max Supply");      
        uint256[] memory ids = new uint256[](mintCount);
        uint256[] memory amounts = new uint256[](mintCount);
        uint256 id = 0;
        for(uint i = 0; i < mintCount; i++) {
            id  = currentSupply % TOKEN_SIZE;
            ids[i] = id;        
            amounts[i] = 1;
            currentSupply = currentSupply + 1;        
        }
        _mintBatch(msg.sender, ids, amounts, "");
    }

    function publicSale(uint256 mintCount, bytes32[] calldata merkleProof)
        external
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(_publicSalePrice, mintCount)
    {
        require(currentSupply + mintCount <= TOTAL_TOKEN_COOUNT, "Overflow Max Supply");
        for(uint i = 0; i < mintCount; i++) {
            _mint(msg.sender, _tokenIdTracker.current(), 1, "");
        }
        currentSupply = currentSupply + mintCount;
    }


    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        // console.log("Merkle Root is");
        // console.logBytes32(merkleRoot);
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