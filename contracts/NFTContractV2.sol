//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTContract is ERC1155Supply, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 TOKEN_SIZE = 10;
    uint8 COUNT_PER_TOKEN = 2;
    uint256 TOTAL_TOKEN_COUNT = TOKEN_SIZE * COUNT_PER_TOKEN;

    uint256 PRESALE_COUNT = 5;
    uint256 PUBLIC_SALE_COUNT = 3;
    
    
    uint8[400] countPerNFT; //default token size is 10 but it is adjustable

    // Minting Prices Per stage
    uint256 _privateSalePrice = 300 wei; 
    uint256 _publicSalePrice = 600 wei; 

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    uint256 private currentSupply = 0; //start index
    uint256 private idPointer = 0;
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

    function calculateTotalSupply() private {
        uint256 totalSize;
        for(uint16 i = 0; i < countPerNFT.length; i++) {
            if(countPerNFT[i] == 0) {
                totalSize += COUNT_PER_TOKEN;
            }else {
                totalSize +=countPerNFT[i];
            }
        }

        TOTAL_TOKEN_COUNT = totalSize;         
    }
    function setSizeOfNFTbyId(uint16 id, uint8 count) external onlyOwner {
        require(id >= 0, "id is wrong");
        require(count > 0, "count is wrong");
        TOTAL_TOKEN_COUNT = TOTAL_TOKEN_COUNT - this.getSizeofNFTbyId(id);
        countPerNFT[id] = count;
         TOTAL_TOKEN_COUNT += count;
        //calculateTotalSupply();
    }

    // function setSizeOfNFTBatch(uint16[] calldata nftIds, uint8[] calldata counts) external onlyOwner{
    //     for(uint8 i = 0; i < nftIds.length; i++){
    //         countPerNFT[nftIds[i]] = counts[i];
    //     }
    //     calculateTotalSupply();
    // }

    function getSizeofNFTbyId(uint256 id) view external onlyOwner returns(uint8){
        require(id < TOKEN_SIZE, "id is wrong. Exceed the maximum id");
        require(id >= 0, "id can't negetive");
        if(countPerNFT[id] == 0){
            //not set and returns default token count;
            return COUNT_PER_TOKEN;
        } else {
            return countPerNFT[id];
        }
    }

    function preSale(uint256 mintCount, bytes32[] calldata merkleProof)
        external
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(_privateSalePrice, mintCount)
    {
        require(mintCount <= PRESALE_COUNT, "Can mint up to 5 NFTs");
        require(currentSupply + mintCount <= TOTAL_TOKEN_COUNT, "Overflow Max Supply");      
        for(uint i = 0; i < mintCount; i++) {
            uint256 id  = getAvailableId();
            _mint(msg.sender, id, 1, "");
            currentSupply = currentSupply + 1;
        }
        
    }

    function getAvailableId() private returns(uint256){
        uint256 expected = idPointer % TOKEN_SIZE; 
        while(totalSupply(expected) > this.getSizeofNFTbyId(expected)) {
            idPointer ++;
            expected = idPointer % TOKEN_SIZE;
        }
        return expected;
    }

    function publicSale(uint256 mintCount)
        external
        payable
        isCorrectPayment(_publicSalePrice, mintCount)
    {
        require(mintCount <= PUBLIC_SALE_COUNT, "Can mint up to 5 NFTs");
        require(currentSupply + mintCount <= TOTAL_TOKEN_COUNT, "Overflow Max Supply");
        for(uint i = 0; i < mintCount; i++) {
            uint256 id  = getAvailableId();
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
