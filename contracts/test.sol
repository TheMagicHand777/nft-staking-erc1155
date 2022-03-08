// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MetaMiniYouthClubNFT is ERC721Enumerable, Ownable, ReentrancyGuard{
    
    string private _collectionURI;
    string public baseTokenURI = "";

    using Counters for Counters.Counter;
    
    /*
      * Reserved max supply is 100
      * POAP airdrop max supply is 500
      * Presale and Public Sale max supply is 6400
    */
    uint256 constant MAX_GIVEAWAY = 100;
    uint256 constant MAX_POAPAIRDROP = 500;
    uint256 constant MAX_EXTRA = 6400;
    uint256 constant MAX_TOTAL = 7000;

    // Minting Prices Per stage
    uint256 public constant WHITELIST_SALE_PRICE = 0.06 ether;
    uint256 public constant PUBLIC_SALE_PRICE = 0.07 ether;

    // Minting limitation variable
    uint constant PRESALE_MAX_PUBLIC_COUNT = 5;  
    uint constant PUBSALE_MAX_PUBLIC_COUNT = 10;  

    // Minting stages
    enum STAGE { BEFORE_MINT, PRE_SALE, PUBLIC_SALE }
    
    // state variable
    STAGE public CURRENT_STAGE = STAGE.BEFORE_MINT;
    
    struct MintInfoItem {
        uint presaleCount;
        uint pubsaleCount;
        uint mintOrder;
        bool poapAirdropClaimable;  // false: not claimable, true: claimable
        bool discordGiveawayClaimed;  // false: not claimed, true: claimed
    }

    // keep track of those on how many tokens are minted per wallet
    mapping(address => MintInfoItem) private _mintInfoList;
    mapping(address => bool) private _presaledMinters;

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;
    bytes32 public ownerMerkleRoot;

    Counters.Counter private _tokenIdTracker;
    uint256 public _giftTokenCount = 0;
    uint256 public _mintOrderTracker = 0;
    
    constructor() ERC721("MetaMiniYouthClub NFT", "MYCN") {
    }

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

    modifier onlyowner(bytes32[] memory merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                ownerMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "This function can be called only by owner"
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

    modifier canPresaleMint(uint256 numberOfTokens) {
        require(
            _mintInfoList[msg.sender].presaleCount + numberOfTokens <= PRESALE_MAX_PUBLIC_COUNT,
            "Overflow max presale minting tokens"
        );
        _;
    }

    modifier canPubsaleMint(uint256 numberOfTokens) {
        require(
            _mintInfoList[msg.sender].pubsaleCount + numberOfTokens <= PUBSALE_MAX_PUBLIC_COUNT,
            "Overflow max presale minting tokens"
        );
        _;
    }

    /**
    * @dev mints 5 token per whitelisted address
    */
    function mintWhitelist(uint256 mintCount, bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(WHITELIST_SALE_PRICE, mintCount)
        canPresaleMint(mintCount)
        nonReentrant
    {
        require(CURRENT_STAGE == STAGE.PRE_SALE, "Current stage should be PRE_SALE");
        require(super.totalSupply() + mintCount <= MAX_EXTRA, "Overflow Max Supply");
        if (!_presaledMinters[msg.sender] && _mintOrderTracker < 500) {
          _mintOrderTracker++;  
          _mintInfoList[msg.sender].poapAirdropClaimable = true;
          _mintInfoList[msg.sender].mintOrder = _mintOrderTracker;
        }
        for (uint256 index = 0; index < mintCount; index++) {
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current());
            _mintInfoList[msg.sender].presaleCount = _mintInfoList[msg.sender].presaleCount + 1;
        }
    }

    /**
    * @dev mints number of tokens to sender address
    */
    function publicMint(uint256 mintCount)
        public
        payable
        isCorrectPayment(PUBLIC_SALE_PRICE, mintCount)
        canPubsaleMint(mintCount)
        nonReentrant
    {
        require(CURRENT_STAGE == STAGE.PUBLIC_SALE, "Current stage should be PUBLIC_SALE");
        require(super.totalSupply() + mintCount <= MAX_EXTRA, "Overflow Max Supply");
        for (uint256 i = 0; i < mintCount; i++) {
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current());
            _mintInfoList[msg.sender].pubsaleCount = _mintInfoList[msg.sender].pubsaleCount + 1;
        }
    }

    /**
    * @dev mints 1 token per whitelisted gift address, does not charge a fee
    * Max supply: 600 ()
    */
    function mintPoap(
        bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        nonReentrant
    {
      require(_mintInfoList[msg.sender].poapAirdropClaimable, "You aren't registered as a POAP airdrop minter");
      _tokenIdTracker.increment();
      _mint(msg.sender, _tokenIdTracker.current());
      _mintInfoList[msg.sender].poapAirdropClaimable = false;
    }

    function mintGiveaway() public nonReentrant {
      require(_mintInfoList[msg.sender].discordGiveawayClaimed, "You aren't registered as a giveaway minter");  
      _tokenIdTracker.increment();
      _mint(msg.sender, _tokenIdTracker.current());
      _mintInfoList[msg.sender].discordGiveawayClaimed = false;
    }

    function ownerMint() public onlyOwner {
        require(super.totalSupply() + 1 < MAX_TOTAL, "Maximum supply reached.");
        _tokenIdTracker.increment();
        _mint(msg.sender, _tokenIdTracker.current());
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    
        whitelistMerkleRoot = merkleRoot;
    }

    function setOwnerMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        ownerMerkleRoot = merkleRoot;
    }

    function setStage(uint256 _stage) external onlyOwner {
        CURRENT_STAGE = STAGE(_stage);
    }

    function getStage() public view returns(STAGE) {
        return CURRENT_STAGE;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function addRecipient(address[] memory params) public onlyOwner {
        require(_giftTokenCount + params.length < MAX_GIVEAWAY, "Overflow MAX Giveaway");
        for(uint128 i = 0; i < params.length; i++) {
            _mintInfoList[params[i]].discordGiveawayClaimed = true;
            _giftTokenCount++;
        }
    }

    /**
    * @dev set collection URI for marketplace display
    */
    function setCollectionURI(string memory collectionURI) internal virtual onlyOwner {
        _collectionURI = collectionURI;
    }

    function getMintOrder(address walletAddress) public view returns(uint256) {
        return _mintInfoList[walletAddress].mintOrder;
    }
    /**
    * @dev withdraw all funds from contract for to specified account
    */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
    * @dev transferring _amount Ether to 
    * the _recipient address from the contract.
    * 
    * requires: enough balance
    * 
    * @return true if transfer was successful
    */
    function transferPartial(
        bytes32[] calldata merkleProof,
        address payable _recipient, 
        uint _amount
    ) 
        external
        onlyowner(merkleProof) 
        returns (bool) 
    {
        require(address(this).balance >= _amount, 'Not enough Ether in contract!');
        _recipient.transfer(_amount);
        
        return true;
    }
}
