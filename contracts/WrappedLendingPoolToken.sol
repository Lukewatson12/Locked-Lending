pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/iLockedLendingPoolToken.sol";
import "./LendingPoolErc20.sol";
import "./interface/iLockedLendingPoolToken.sol";

// Can look at > https://eips.ethereum.org/EIPS/eip-1155
contract WrappedLendingPoolToken is ERC721, iLockedLendingPoolToken {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private tokenIds;

    mapping(uint256 => iLockedLendingPoolToken.LLPNFT) LLPNFTMapping;

    address lendingPoolTokenAddress;
    IERC20 lendingPoolToken;

    constructor(address _lendingPoolTokenAddress)
        public
        ERC721("Locked Lending", "LLPT")
    {
        lendingPoolToken = IERC20(_lendingPoolTokenAddress);
    }

    function lockLendingPoolToken(uint256 _amount, uint256 _duration)
        public
        override
        returns (uint256)
    {
        require(
            lendingPoolToken.allowance(msg.sender, address(this)) >= _amount,
            "Not enough allowance"
        );
        require(
            lendingPoolToken.balanceOf(msg.sender) >= _amount,
            "Not enough LP tokens"
        );
        require(_amount > 0, "Amount must be above 0");
        require(_duration > 0, "Duration must be more than 0 seconds");

        tokenIds.increment();
        uint256 lockedLendingPoolTokenId = tokenIds.current();
        _safeMint(msg.sender, lockedLendingPoolTokenId);

        LLPNFTMapping[lockedLendingPoolTokenId] = iLockedLendingPoolToken
            .LLPNFT({
            lockStart: block.timestamp,
            lockEnd: block.timestamp.add(_duration),
            amount: _amount,
            isEntity: true
        });

        lendingPoolToken.transferFrom(msg.sender, address(this), _amount);

        return lockedLendingPoolTokenId;
    }

    function withdraw(uint256 _id) public override {
        require(_isApprovedOrOwner(msg.sender, _id), "Not the owner");
        require(LLPNFTMapping[_id].isEntity, "Token does not exist");
        require(
            block.timestamp >= LLPNFTMapping[_id].lockEnd,
            "Tokens are still locked"
        );

        lendingPoolToken.transfer(ownerOf(_id), LLPNFTMapping[_id].amount);

        _burn(_id);

        LLPNFTMapping[_id] = iLockedLendingPoolToken.LLPNFT({
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
            bool isEntity
        )
    {
        return (
            LLPNFTMapping[_id].lockStart,
            LLPNFTMapping[_id].lockEnd,
            LLPNFTMapping[_id].amount,
            LLPNFTMapping[_id].isEntity
        );
    }

    function getToken(uint256 _id)
        external
        view
        returns (uint256)
    {
        return (1);
//        return (
//            LLPNFTMapping[_id].lockStart,
//            LLPNFTMapping[_id].lockEnd,
//            LLPNFTMapping[_id].amount
//        );
    }
}