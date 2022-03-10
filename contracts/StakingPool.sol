// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract NftStaking is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public constant REWT_ISSUE_CNT_PER_SECOND = 27; // rewt token issue count per second, 10,000 per hour
  uint256 public constant LEVELUP_PERCENT = 10; // level up nft percent per 30 days
  uint256 public constant LEVELUP_DEADLINE_BY_SECONDS = 30; // level up deadline by seconds
  struct NftNFTStakerInfo {
    uint256 rewardValue;
    uint256 claimRewardTime;
    uint256 nftRewardPoint;
  }

  address[] private stakers;
  mapping(address => uint256[]) private stakerToNftTokenIds;  //staked token ids of address
  //address=>id=>amount
  mapping(address => mapping(uint256=>uint256)) private stakerToNftTokens;  //staked tokens count of address
  mapping(address => NftNFTStakerInfo) private nftStakerInfo;


  address private admin;
  address private rewtTokenAddress;
  address private nftNFTAddress;
  ERC20 private rewtTokenInterface;
  ERC1155Supply private nftNFTInterface;

  constructor(address pRewTTokenAddress, address pNftNFTAddress) {
    require(msg.sender != address(0x0), "Cannot deploy staking contract from address 0x0.");
    admin = msg.sender;
    rewtTokenInterface = ERC20(pRewTTokenAddress);
    nftNFTInterface = ERC1155Supply(pNftNFTAddress);
  }

  function getNftTokenidByStaker(address pStaker) public view returns (uint256[] memory) {
    return stakerToNftTokenIds[pStaker];
  }

  function getStakedCountByStaker(address pStaker) public view returns (uint256) {
    return stakerToNftTokenIds[pStaker].length;
  }

  // function getNftStakedTimeByTokenid(uint256 pTokenId) public view returns (uint256) {
  //   return nftStakedTimeByTokenId[pTokenId];
  // }
  function setRewTTokenAddress(address pTokenAddress) public onlyOwner {
    require(pTokenAddress != address(0), "The token address should not be address 0x0.");
    rewtTokenAddress = pTokenAddress;
    rewtTokenInterface = ERC20(rewtTokenAddress);
  }

  function setNftNFTAddress(address pNFTAddress) public onlyOwner {
    require(pNFTAddress != address(0), "The NFT address should not be address 0x0.");
    nftNFTAddress = pNFTAddress;
    nftNFTInterface = ERC1155Supply(nftNFTAddress);
  }

  function stake(uint256 tokenId) external nonReentrant {
    require(nftNFTInterface.balanceOf(msg.sender, tokenId) != 0, "This NFT is not yours.");
    // require(nftTokenIdToStaker[tokenId] == address(0), "This NFT is already staked.");
    nftNFTInterface.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
    _updateRewardOfStakers();

    stakerToNftTokens[msg.sender][tokenId] += 1; 

    nftStakerInfo[msg.sender].claimRewardTime = block.timestamp;
    nftStakerInfo[msg.sender].nftRewardPoint += 1;
    addStaker(msg.sender);    
  }

  function unstake(uint256 tokenId) external nonReentrant {
    require(stakerToNftTokens[msg.sender][tokenId] >= 1, "Not staked by you.");
    nftNFTInterface.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
    _updateRewardOfStakers();

    rewtTokenInterface.transferFrom(address(this), msg.sender, nftStakerInfo[msg.sender].rewardValue);
    stakerToNftTokens[msg.sender][tokenId] -= 1;

    //
    if(checkNoStakingNFT(msg.sender) == true) {
      removeStaker(msg.sender);
    }
  }

  function checkNoStakingNFT(address unstaker) private view returns(bool) {
    uint[] memory tokenIds = stakerToNftTokenIds[unstaker];
    uint256 tokenCounts = 0;
    for(uint i = 0; i < tokenIds.length; i++) {
      tokenCounts += stakerToNftTokens[unstaker][tokenIds[i]];
    }
    if(tokenCounts > 0) {
      return false; //there is staking NFTs
    }
    return true; //there is no NFTs
  }

  function removeStaker(address unstaker) private {
    for(uint8 i = 0; i < stakers.length; i++) {
      if(stakers[i] == unstaker){
        stakers[i] == stakers[stakers.length - 1];
        stakers.pop();
        return;
      }
    }
  }

  function addStaker(address staker) private {
    uint256 j = 0;
    for (uint256 i = 0; i < stakers.length; i++) {
      if (stakers[i] == staker)
        break;
      else
        j++;
    }
    if (stakers.length == j) stakers.push(staker);
  }


  function _updateRewardOfStakers() private {
    for (uint256 i=0; i<stakers.length; i++) {
      address staker = stakers[i];
      uint256 timeDiff = block.timestamp - nftStakerInfo[staker].claimRewardTime;
      nftStakerInfo[staker].rewardValue += timeDiff / 10; //increase reward point per 10 second
      nftStakerInfo[staker].claimRewardTime = block.timestamp;      
    }
  }
}