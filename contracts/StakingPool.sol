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

  struct NFTStakingInfo {
    //reward value remains
    uint256 rewardValue;
    //last reward claim time
    uint256 claimRewardTime;
    //total staked count
    uint256 stakedNFTCount;
    //ids
    uint256[] stakedTokenIds; //unused now, not sure it needs
    //id=>amount
    mapping(uint256=>uint256) sizeOfStakedIndividualToken;
  }

  mapping(address => NFTStakingInfo) private stakingInfo;


  address private _rewardTokenAddress;
  address private _nftTokenAddress;
  ERC20 private _rewardTokenInterface;
  ERC1155Supply private _nftInterface;

  constructor(address rewardTokenAddress, address nftTokenAddress) {
    _rewardTokenAddress = rewardTokenAddress;
    _nftTokenAddress = nftTokenAddress;
    _rewardTokenInterface = ERC20(rewardTokenAddress);
    _nftInterface = ERC1155Supply(nftTokenAddress);
  }

  // function getNftTokenidByStaker(address pStaker) public view returns (uint256[] memory) {
  //   return stakerToNftTokenIds[pStaker];
  // }

  // function getStakedCountByStaker(address pStaker) public view returns (uint256) {
  //   return stakerToNftTokenIds[pStaker].length;
  // }

  // function setRewTTokenAddress(address pTokenAddress) public onlyOwner {
  //   require(pTokenAddress != address(0), "The token address should not be address 0x0.");
  //   rewtTokenAddress = pTokenAddress;
  //   rewtTokenInterface = ERC20(rewtTokenAddress);
  // }

  // function setNftNFTAddress(address pNFTAddress) public onlyOwner {
  //   require(pNFTAddress != address(0), "The NFT address should not be address 0x0.");
  //   nftNFTAddress = pNFTAddress;
  //   nftNFTInterface = ERC1155Supply(nftNFTAddress);
  // }

  function stake(uint256 tokenId) external nonReentrant {
    require(_nftInterface.balanceOf(msg.sender, tokenId) != 0, "This NFT is not yours.");
    _nftInterface.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

    stakingInfo[msg.sender].sizeOfStakedIndividualToken[tokenId] += 1; 
    stakingInfo[msg.sender].stakedNFTCount += 1;
    if(stakingInfo[msg.sender].claimRewardTime == 0) { //when this is the first stake
      stakingInfo[msg.sender].claimRewardTime = block.timestamp;
    }

    _updateRewardOfStaker(msg.sender);
  }

  // function unstake(uint256 tokenId) external nonReentrant {
  //   require(stakerToNftTokens[msg.sender][tokenId] >= 1, "Not staked by you.");
  //   nftNFTInterface.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
  //   _updateRewardOfStakers();

  //   rewtTokenInterface.transferFrom(address(this), msg.sender, stakingInfo[msg.sender].rewardValue);
  //   stakerToNftTokens[msg.sender][tokenId] -= 1;

  //   //
  //   if(checkNoStakingNFT(msg.sender) == true) {
  //     removeStaker(msg.sender);
  //   }
  // }

  // function checkNoStakingNFT(address unstaker) private view returns(bool) {
  //   uint[] memory tokenIds = stakerToNftTokenIds[unstaker];
  //   uint256 tokenCounts = 0;
  //   for(uint i = 0; i < tokenIds.length; i++) {
  //     tokenCounts += stakerToNftTokens[unstaker][tokenIds[i]];
  //   }
  //   if(tokenCounts > 0) {
  //     return false; //there is staking NFTs
  //   }
  //   return true; //there is no NFTs
  // }

  // function removeStaker(address unstaker) private {
  //   for(uint8 i = 0; i < stakers.length; i++) {
  //     if(stakers[i] == unstaker){
  //       stakers[i] == stakers[stakers.length - 1];
  //       stakers.pop();
  //       return;
  //     }
  //   }
  // }

  // function addStaker(address staker) private {
  //   uint256 j = 0;
  //   for (uint256 i = 0; i < stakers.length; i++) {
  //     if (stakers[i] == staker)
  //       break;
  //     else
  //       j++;
  //   }
  //   if (stakers.length == j) stakers.push(staker);
  // }

  function _updateRewardOfStaker(address staker) private {
    NFTStakingInfo storage info = stakingInfo[staker];
    uint256 timeDiff = block.timestamp - info.claimRewardTime;
    info.rewardValue += timeDiff * info.stakedNFTCount;
    info.claimRewardTime = block.timestamp;    
  }
}