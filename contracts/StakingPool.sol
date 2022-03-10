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
    uint256 lastStakedTime;
    uint256 nftRewardPoint;
  }

  address[] private stakers;
  mapping(address => uint256[]) private stakerToNftTokenIds;  //staked token ids of address
  //address=>id=>amount
  mapping(address => mapping(uint256=>uint256)) private stakerToNftTokens;  //staked tokens count of address

  // mapping(uint256 => address) private nftTokenIdToStaker;
  // mapping(uint256 => uint256) private nftStakedTimeByTokenId;
  // mapping(uint256 => uint256) private nftRewardPoint;
  mapping(uint256 => NftNFTStakerInfo) private nftTokenIdToStakerInfo;


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

    stakerToNftTokenIds[msg.sender].push(tokenId);
    stakerToNftTokens[msg.sender][tokenId] += 1; 
    nftStakedTimeByTokenId[tokenId] = block.timestamp;
    // nftTokenIdToStaker[tokenId] = msg.sender;
    nftRewardPointByTokenId[tokenId] = 1;
    NftNFTStakerInfo memory temp;
    temp.reward = 0;
    nftTokenIdToStakerInfo[tokenId] = temp;
    uint256 j = 0;
    for (uint256 i = 0; i < stakers.length; i++) {
      if (stakers[i] == msg.sender)
        break;
      else
        j++;
    }
    if (stakers.length == j) stakers.push(msg.sender);
  }
  function unstake(uint256 pTokenId) external nonReentrant {
    require(nftTokenIdToStaker[pTokenId] == msg.sender, "Not staked by you.");
    nftNFTInterface.transferFrom(address(this), msg.sender, pTokenId);
    _updateRewardOfStakers();
    rewtTokenInterface.transferFrom(address(this), msg.sender, nftTokenIdToStakerInfo[pTokenId].reward);
    for (uint256 i=0; i<stakerToNftTokenIds[msg.sender].length; i++) {
      uint256 tokenId = stakerToNftTokenIds[msg.sender][i];
      if (tokenId == pTokenId) {
        stakerToNftTokenIds[msg.sender][i] = stakerToNftTokenIds[msg.sender][getStakedCountByStaker(msg.sender)-1];
        stakerToNftTokenIds[msg.sender].pop();
        break;
      }
    }
    nftTokenIdToStaker[pTokenId] = address(0);
  }
  function _updateRewardOfStakers() internal {
    uint256 stakedNftNFTCnt = 0;
    for (uint256 i=0; i<stakers.length; i++) {
      for (uint256 j=0; j<stakerToNftTokenIds[stakers[i]].length; j++) {
        stakedNftNFTCnt++;
      }
    }
    for (uint256 i=0; i<stakers.length; i++) {
      address staker = stakers[i];
      for (uint256 j=0; j<stakerToNftTokenIds[staker].length; j++) {
        uint256 tokenId = stakerToNftTokenIds[staker][j];
        uint256 timeDiff = block.timestamp - nftStakedTimeByTokenId[tokenId];
        uint256 levelUpCnt = timeDiff.div(LEVELUP_DEADLINE_BY_SECONDS);
        for (uint256 k=0; k<levelUpCnt; k++) {
          nftRewardPointByTokenId[tokenId].mul(100 + LEVELUP_PERCENT / 100);
        }
        uint256 rewardPerNftNFT = REWT_ISSUE_CNT_PER_SECOND.div(stakedNftNFTCnt);
        nftTokenIdToStakerInfo[tokenId].reward += rewardPerNftNFT.mul(timeDiff);
        nftStakedTimeByTokenId[tokenId] = block.timestamp;
      }
    }
  }
}