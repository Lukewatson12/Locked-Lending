pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./WrappedLendingPoolToken.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;

    address public constant wrappedLendingPoolTokenAddress = address(
        0xf278DDe7F235D1736d1981a036637A5B9Cf20316
    );

    WrappedLendingPoolToken private wrappedLendingPoolToken;

    uint256 private countNftStaked;
    uint256 private countLpTokensStaked;
    uint256 private adjustedTotalStaked;

    mapping(address => uint256) private myStake;
    mapping(address => LLPNFT[]) private owned;

    constructor() public {
        wrappedLendingPoolToken = WrappedLendingPoolToken(wrappedLendingPoolTokenAddress);
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

    function calculateCoverValue(
        uint256 amount,
        uint256 lockStart,
        uint256 lockEnd
    ) public view returns (uint256) {
        return 10;
        //        uint256 per = x.mul(multiplier).div(y);
        //        return multiplier.sub(per).mul(coverAmount).div(multiplier);
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

    function calculateStakeValue(
        uint256 coverAmount,
        uint256 generationTime,
        uint256 expirationTimestamp
    ) public view returns (uint256) {
        // generationTime is in milliseconds, expirationTimestamp is in seconds
        uint256 x = block.timestamp.mul(1000).sub(generationTime);
        uint256 y = expirationTimestamp.mul(1000).sub(generationTime);
        uint256 multiplier = 100000;
        uint256 per = x.mul(multiplier).div(y);
        return multiplier.sub(per).mul(coverAmount).div(multiplier);
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

    function getToken(uint256 _id)
        public
        view
        returns (
    bool
//            uint256 ,
//            uint256 ,
//            uint256
        )
    {
        wrappedLendingPoolToken.getToken(_id);

        return true;
    }

    function stake(uint256 _tokenId) public virtual {
//        (uint256 lockStart, uint256 lockEnd, uint256 amount) = getToken(
//            _tokenId
//        );

        //        require(
        //            lockEnd - 24 hours > block.timestamp,
        //            "Cover has expired or is 24 hours away from expiring!"
        //        );
        //
        //        require(amount > 0, "Staked amount must be more than 0");
        //
        //        owned[msg.sender].push(
        //            LLPNFT(lockStart, lockEnd, amount, _tokenId, false)
        //        );
        //
        //        countNftStaked = countNftStaked.add(1);
        //        countLpTokensStaked = countLpTokensStaked.add(amount);
        //        myStake[msg.sender] = myStake[msg.sender].add(amount);
        //
        //        lendingPoolNft.transferFrom(msg.sender, address(this), _tokenId);
    }

    function withdraw(uint256 _tokenId) public virtual {
        for (uint256 i = 0; i < owned[msg.sender].length; i++) {
            if (
                owned[msg.sender][i].id == _tokenId &&
                !owned[msg.sender][i].isWithdrawn
            ) {
                countNftStaked = countNftStaked.sub(1);
                countLpTokensStaked = countLpTokensStaked.sub(
                    owned[msg.sender][i].amount
                );
                myStake[msg.sender] = myStake[msg.sender].sub(
                    owned[msg.sender][i].amount
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

    struct LLPNFT {
        uint256 id;
        uint256 lockStart;
        uint256 lockEnd;
        uint256 amount;
        bool isWithdrawn;
    }
}
