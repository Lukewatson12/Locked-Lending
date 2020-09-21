pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./WrappedLendingPoolToken.sol";
import "./interface/iLockedLendingPoolToken.sol";

contract LPTokenWrapper is IERC721Receiver {
    using SafeMath for uint256;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    WrappedLendingPoolToken private wrappedLendingPoolToken;

    uint256 private countNftStaked;
    uint256 private countLpTokensStaked;
    uint256 private adjustedTotalStaked;

    mapping(address => uint256) private myStake;
    mapping(address => LLPNFT[]) private owned;

    // todo this is terrible
    function setWrappedLendingPoolToken(address _address) public {
        wrappedLendingPoolToken = WrappedLendingPoolToken(_address);
    }

    function totalStaked() public view returns (uint256) {
        return countLpTokensStaked;
    }

    function totalSupply() public view returns (uint256) {
        return adjustedTotalStaked;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return myStake[_account];
    }

    function numStaked(address account) public view returns (uint256) {
        uint256 staked = 0;
        for (uint256 i = 0; i < owned[account].length; i++) {
            if (!owned[account][i].isWithdrawn) {
                staked++;
            }
        }
        return staked;
    }

    function calculateLendingValue(
        iLockedLendingPoolToken.LockPeriod _lockPeriod,
        uint256 _numberOfLendingPoolTokens
    ) public view returns (uint256) {
        return
            _numberOfLendingPoolTokens.mul(
                determineLockPeriodMultiplier(_lockPeriod)
            );
    }

    function determineLockPeriodMultiplier(
        iLockedLendingPoolToken.LockPeriod _lockPeriod
    ) public view returns (uint256) {
        if (_lockPeriod == iLockedLendingPoolToken.LockPeriod.THREE_MONTHS) {
            return 10;
        } else if (
            _lockPeriod == iLockedLendingPoolToken.LockPeriod.SIX_MONTHS
        ) {
            return 25;
        } else if (
            _lockPeriod == iLockedLendingPoolToken.LockPeriod.TWELVE_MONTHS
        ) {
            return 75;
        }

        return 0;
    }

    function idsStaked(address account) public view returns (uint256[] memory) {
        uint256[] memory staked = new uint256[](numStaked(account));
        uint256 tempIdx = 0;
        for (uint256 i = 0; i < owned[account].length; i++) {
            if (!owned[account][i].isWithdrawn) {
                staked[tempIdx] = owned[account][i].id;
                tempIdx++;
            }
        }
        return staked;
    }

    function stake(uint256 _tokenId) public virtual {
        (
            uint256 lockStart,
            uint256 lockEnd,
            uint256 amount,
            iLockedLendingPoolToken.LockPeriod lockPeriod
        ) = getToken(_tokenId);

        require(
            lockEnd - 24 hours > block.timestamp,
            "Cover has expired or is 24 hours away from expiring!"
        );

        require(amount > 0, "Staked amount must be more than 0");

        uint256 lendingValue = calculateLendingValue(lockPeriod, amount);

        owned[msg.sender].push(
            LLPNFT(_tokenId, lockStart, lockEnd, amount, lendingValue, false)
        );

        countNftStaked = countNftStaked.add(1);
        countLpTokensStaked = countLpTokensStaked.add(amount);
        myStake[msg.sender] = myStake[msg.sender].add(amount);

        wrappedLendingPoolToken.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
    }

    function withdraw(uint256 _tokenId) public virtual {
        for (uint256 i = 0; i < owned[msg.sender].length; i++) {
            if (
                owned[msg.sender][i].id == _tokenId &&
                !owned[msg.sender][i].isWithdrawn
            ) {
                countNftStaked = countNftStaked.sub(1);
                countLpTokensStaked = countLpTokensStaked.sub(
                    owned[msg.sender][i].lendingPoolTokens
                );
                myStake[msg.sender] = myStake[msg.sender].sub(
                    owned[msg.sender][i].lendingPoolTokens
                );

                owned[msg.sender][i].isWithdrawn = true;
                wrappedLendingPoolToken.transferFrom(
                    address(this),
                    msg.sender,
                    _tokenId
                );
            }
        }
    }

    function withdrawAll() public virtual {
        for (uint256 i = 0; i < owned[msg.sender].length; i++) {
            if (!owned[msg.sender][i].isWithdrawn) {
                withdraw(i);
            }
        }
    }

    function getToken(uint256 _id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            iLockedLendingPoolToken.LockPeriod
        )
    {
        return wrappedLendingPoolToken.getToken(_id);
    }

    struct LLPNFT {
        uint256 id;
        uint256 lockStart;
        uint256 lockEnd;
        uint256 lendingPoolTokens;
        uint256 lendingValue;
        bool isWithdrawn;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}
