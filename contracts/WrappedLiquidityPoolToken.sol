pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/iLockedLiquidityPoolToken.sol";
import "./LiquidityPoolErc20.sol";
import "./interface/iLockedLiquidityPoolToken.sol";

// Can look at > https://eips.ethereum.org/EIPS/eip-1155
contract WrappedLiquidityPoolToken is ERC721, iLockedLiquidityPoolToken {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private tokenIds;

    mapping(uint256 => iLockedLiquidityPoolToken.LLPNFT) LLPNFTMapping;

    address liquidityPoolTokenAddress;
    IERC20 liquidityPoolToken;

    constructor(address _liquidityPoolTokenAddress)
        public
        ERC721("Locked Liquidity", "LLPT")
    {
        liquidityPoolToken = IERC20(_liquidityPoolTokenAddress);
    }

    function lockLiquidityPoolToken(uint256 _amount, LockPeriod _lockPeriod)
        public
        override
        returns (uint256)
    {
        require(
            liquidityPoolToken.allowance(msg.sender, address(this)) >= _amount,
            "Not enough allowance"
        );

        require(
            liquidityPoolToken.balanceOf(msg.sender) >= _amount,
            "Not enough LP tokens"
        );

        require(_amount > 0, "Amount must be above 0");
        require(
            _lockPeriod != LockPeriod.FINISHED,
            "Must set a valid lock period"
        );

        tokenIds.increment();
        uint256 lockedLiquidityPoolTokenId = tokenIds.current();
        _safeMint(msg.sender, lockedLiquidityPoolTokenId);

        LLPNFTMapping[lockedLiquidityPoolTokenId] = iLockedLiquidityPoolToken
            .LLPNFT({
            lockPeriod: _lockPeriod,
            lockStart: block.timestamp,
            lockEnd: block.timestamp.add(determineLockDuration(_lockPeriod)),
            amount: _amount,
            isEntity: true
        });

        liquidityPoolToken.transferFrom(msg.sender, address(this), _amount);

        return lockedLiquidityPoolTokenId;
    }

    function withdraw(uint256 _id) public override {
        require(_isApprovedOrOwner(msg.sender, _id), "Not the owner");
        require(LLPNFTMapping[_id].isEntity, "Token does not exist");
        require(
            block.timestamp >= LLPNFTMapping[_id].lockEnd,
            "Tokens are still locked"
        );

        liquidityPoolToken.transfer(ownerOf(_id), LLPNFTMapping[_id].amount);

        _burn(_id);

        LLPNFTMapping[_id] = iLockedLiquidityPoolToken.LLPNFT({
            lockPeriod: LockPeriod.FINISHED,
            lockStart: 0,
            lockEnd: 0,
            amount: 0,
            isEntity: false
        });
    }

    // todo allow transfer and post owner address
    function getTokenById(uint256 _id)
        external
        override
        view
        returns (
            uint256 lockStart,
            uint256 lockEnd,
            uint256 amount,
            bool isEntity,
            LockPeriod lockPeriod
        )
    {
        return (
            LLPNFTMapping[_id].lockStart,
            LLPNFTMapping[_id].lockEnd,
            LLPNFTMapping[_id].amount,
            LLPNFTMapping[_id].isEntity,
            LLPNFTMapping[_id].lockPeriod
        );
    }

    function getToken(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            LockPeriod
        )
    {
        return (
            LLPNFTMapping[_id].lockStart,
            LLPNFTMapping[_id].lockEnd,
            LLPNFTMapping[_id].amount,
            LLPNFTMapping[_id].lockPeriod
        );
    }

    function determineLockDuration(LockPeriod _lockPeriod)
        internal
        view
        returns (uint256)
    {
        if (_lockPeriod == LockPeriod.THREE_MONTHS) {
            return 31 days;
        } else if (_lockPeriod == LockPeriod.SIX_MONTHS) {
            return 183 days;
        } else if (_lockPeriod == LockPeriod.TWELVE_MONTHS) {
            return 365 days;
        }

        revert("Unable to determine lock period, reverting");
    }
}
