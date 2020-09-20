pragma solidity ^0.6.0;

import "./LPTokenWrapper.sol";
import "./MintableErc20.sol";
import "./interface/IRewardDistributionRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

contract LockedLendingErc20Pool is
    LPTokenWrapper,
    IRewardDistributionRecipient
{
    using SafeERC20 for IERC20;

    MintableErc20 public erc20Token = MintableErc20(
        0x1Aa61c196E76805fcBe394eA00e4fFCEd24FC469
    );

    uint256 public constant DURATION = 30 days;

    uint256 public initReward = 10000 * 1e18;
    uint256 public startTime = 1608854400; // 1608854400 => Friday, 25 December 2020 00:00:00
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 tokenId);
    event WithdrawnAll(address indexed user);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 tokenId)
        public
        override
        updateReward(msg.sender)
        checkHalve
        checkStart
    {
        require(tokenId >= 0, "token id must be >= 0");
        super.stake(tokenId);
        emit Staked(msg.sender, tokenId);
    }

    function stakeMultiple(uint256[] memory tokenIds)
        public
        updateReward(msg.sender)
        checkHalve
        checkStart
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] >= 0, "Token id must be >= 0");
            super.stake(tokenIds[i]);
            emit Staked(msg.sender, tokenIds[i]);
        }
    }

    function withdraw(uint256 tokenId)
        public
        override
        updateReward(msg.sender)
        checkHalve
        checkStart
    {
        require(tokenId >= 0, "token id must be >= 0");
        require(numStaked(msg.sender) > 0, "No Lending Pool NF tokens staked");
        super.withdraw(tokenId);
        emit Withdrawn(msg.sender, tokenId);
    }

    function withdrawMultiple(uint256[] memory tokenIds)
        public
        updateReward(msg.sender)
        checkHalve
        checkStart
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] >= 0, "Token id must be >= 0");
            super.withdraw(tokenIds[i]);
            emit Withdrawn(msg.sender, tokenIds[i]);
        }
    }

    function withdrawAll()
        public
        override
        updateReward(msg.sender)
        checkHalve
        checkStart
    {
        require(numStaked(msg.sender) > 0, "No Lending Pool NF tokens staked");
        super.withdrawAll();
        emit WithdrawnAll(msg.sender);
    }

    function exit() external {
        withdrawAll();
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkHalve checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            erc20Token.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkHalve() {
        if (block.timestamp >= periodFinish) {
            initReward = initReward.mul(50).div(100);
            erc20Token.mint(address(this), initReward);

            rewardRate = initReward.div(DURATION);
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(initReward);
        }
        _;
    }
    modifier checkStart() {
        require(block.timestamp > startTime, "Pool is not open yet");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        erc20Token.mint(address(this), reward);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}
