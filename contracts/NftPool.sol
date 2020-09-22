pragma solidity ^0.6.0;

import "./LPTokenWrapper.sol";
import "./FairToken.sol";
import "./interface/IRewardDistributionRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

contract NftPool is LPTokenWrapper, IRewardDistributionRecipient {
    using SafeERC20 for IERC20;

    FairToken public fairToken;

    // todo remove
    function setToken(address _address) public {
        fairToken = FairToken(_address);
    }

    uint256 public constant DURATION = 30 days;

    uint256 public initialReward = 10000 * 1e18;
    //    uint256 public startTime = 1608854400; // 1608854400 => Friday, 25 December 2020 00:00:00
    uint256 public startTime = block.timestamp; // 1608854400 => Friday, 25 December 2020 00:00:00
    uint256 public endTime = block.timestamp + DURATION;

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

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkStart() {
        require(block.timestamp > startTime, "Pool is not open yet");
        _;
    }

    function hasPoolStarted() public view returns (bool) {
        return block.timestamp >= startTime;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, endTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (getTotalLiquidityValue() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                endTime.sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(
                    getTotalLiquidityValue()
                )
            );
    }

    function earned(address _account) public view returns (uint256) {
        // @dev if this pool has not yet opened, the reward will be null
        if (false == hasPoolStarted()) {
            return 0;
        }

        return
            myLiquidityValue[_account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_account]))
                .div(1e18)
                .add(rewards[_account]);
    }

    function stake(uint256 tokenId) public override updateReward(msg.sender) {
        require(tokenId >= 0, "token id must be >= 0");
        super.stake(tokenId);
        emit Staked(msg.sender, tokenId);
    }

    function stakeMultiple(uint256[] memory tokenIds)
        public
        updateReward(msg.sender)
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
    {
        require(tokenId >= 0, "token id must be >= 0");
        require(
            totalStaked(msg.sender) > 0,
            "No Liquidity Pool NF tokens staked"
        );
        super.withdraw(tokenId);
        emit Withdrawn(msg.sender, tokenId);
    }

    function withdrawMultiple(uint256[] memory tokenIds)
        public
        updateReward(msg.sender)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] >= 0, "Token id must be >= 0");
            super.withdraw(tokenIds[i]);
            emit Withdrawn(msg.sender, tokenIds[i]);
        }
    }

    function withdrawAll() public override updateReward(msg.sender) {
        require(
            totalStaked(msg.sender) > 0,
            "No Liquidity Pool NF tokens staked"
        );
        super.withdrawAll();
        emit WithdrawnAll(msg.sender);
    }

    function exit() external {
        withdrawAll();
        getReward();
    }

    // Used to transfer the accrued rewards out of the contract
    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            fairToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Used to mint the tokens to be given as rewards
    // Reward rate is set each time more rewards are created.
    // Each time more rewards are created, the pools life is extended
    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        fairToken.mint(address(this), reward);
        rewardRate = reward.div(DURATION);
        emit RewardAdded(reward);
    }
}
