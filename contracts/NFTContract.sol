//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";
contract NFTContract is ERC1155, Ownable, ReentrancyGuard {
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 MAX_TOKEN_SIZE = 1000;
    uint256 MAX_COUNT_PER_TOKEN = 30;

    // Minting Prices Per stage
    uint256 _privateSalePrice = 0.0001 ether; 
    uint256 _publicSalePrice = 0.0002 ether; 

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;
    Counters.Counter private _tokenIdTracker;

    string  private _baseUri = "";
    uint256 private currentSupply = 0;
    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        console.logBytes32(merkleProof[0]);    
        console.logBytes32(merkleProof[1]);    
        console.logBytes32(root);
        console.logBytes32(keccak256(abi.encodePacked(msg.sender)));        
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

    constructor(string memory  baseUri) ERC1155("") {    
        _baseUri = baseUri;
    }
    
    function testMint() public onlyOwner {
        _tokenIdTracker.increment();
        _mint(msg.sender, _tokenIdTracker.current(), 1, "");
        _tokenIdTracker.increment();
        _mint(msg.sender, _tokenIdTracker.current(), 1, "");
    }

    function setBaseUri(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function uri( uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(_baseUri, Strings.toString(_id)));
    }
    //mint nfts (only owner of the smart contract can mint nfts)
    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    //Burn nfts (only owner of the nft can burn nft)
    function burn(address account, uint256 id, uint256 amount) public {
        require(msg.sender == account);
        _burn(account, id, amount);
    }

    function preSale(uint256 mintCount, bytes32[] calldata merkleProof)
        external
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(_privateSalePrice, mintCount)
    {
        require(currentSupply + mintCount <= MAX_TOKEN_SIZE, "Overflow Max Supply");
        for(uint i = 0; i < mintCount; i++) {
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current(), 1, "");
        }
        currentSupply = currentSupply + mintCount;
    }

    function publicSale(uint256 mintCount, bytes32[] calldata merkleProof)
        external
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(_publicSalePrice, mintCount)
    {
        require(currentSupply + mintCount <= MAX_TOKEN_SIZE, "Overflow Max Supply");
        for(uint i = 0; i < mintCount; i++) {
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current(), 1, "");
        }
        currentSupply = currentSupply + mintCount;
    }


    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        console.log("Merkle Root is");
        console.logBytes32(merkleRoot);
        whitelistMerkleRoot = merkleRoot;
    }

    function setPrivateSalePrice(uint256 value) public onlyOwner {
        _privateSalePrice = value;
    }

    function getPrivateSalePrice() public view returns (uint256) {
        return _privateSalePrice;
    }

    function setPublicSalePrice(uint256 value) public onlyOwner {
        _publicSalePrice = value;
    }

    function getPublicSalePrice() public view returns (uint256) {
        return _publicSalePrice;
    }
}
