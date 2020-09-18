pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Can look at > https://eips.ethereum.org/EIPS/eip-1155
contract LockedLendingPoolToken is ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    struct LLPNFT {
        uint256 lockStart;
        uint256 lockEnd;
        uint256 amount;
        bool isEntity;
    }

    mapping(uint256 => LLPNFT) LLPNFTMapping;

    constructor() public ERC721("Locked Lending", "LLPT") {}

    function lockLendingPoolToken(
        address _lendingPoolToken,
        uint256 _amount,
        uint256 _duration
    ) public returns (uint256) {
        require(IERC20(_lendingPoolToken).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance");
        require(IERC20(_lendingPoolToken).balanceOf(msg.sender) >= _amount, "Not enough LP tokens");
        require(_amount > 0, "Amount must be above 0");
        require(_duration > 0, "Duration must be more than 0 seconds");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);

        LLPNFTMapping[newItemId] = LLPNFT({
            lockStart : block.timestamp,
            lockEnd : block.timestamp.add(_duration),
            amount : _amount,
            isEntity : true
            });

        IERC20(_lendingPoolToken).transferFrom(msg.sender, address(this), _amount);

        return newItemId;
    }

    function getTokenById(uint256 _id)
    public
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
}
