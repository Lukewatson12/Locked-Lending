pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./WrappedLiquidityPoolToken.sol";
import "./interface/iLockedLiquidityPoolToken.sol";
import "./WrappedLiquidityPoolToken.sol";

contract LPTokenWrapper is IERC721Receiver {
    using SafeMath for uint256;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    WrappedLiquidityPoolToken private wrappedLiquidityPoolToken;

    uint256 private countNftStaked;
    uint256 private totalLiquidityPoolTokens;
    uint256 private totalLiquidityValue;

    mapping(address => uint256) internal myLiquidityTokens;
    mapping(address => uint256) internal myLiquidityValue;
    mapping(address => LLPNFT[]) internal myTokens;

    // todo this is terrible
    function setWrappedLiquidityPoolToken(address _address) public {
        wrappedLiquidityPoolToken = WrappedLiquidityPoolToken(_address);
    }

    function getTotalLiquidityPoolTokens() public view returns (uint256) {
        return totalLiquidityPoolTokens;
    }

    function getTotalLiquidityValue() public view returns (uint256) {
        return totalLiquidityValue;
    }

    function getMyLiquidityValue(address _account)
        public
        view
        returns (uint256)
    {
        return myLiquidityValue[_account];
    }

    function getMyLiquidityTokens(address _account)
        public
        view
        returns (uint256)
    {
        return myLiquidityTokens[_account];
    }

    function totalStaked(address _account) public view returns (uint256) {
        uint256 staked = 0;
        for (uint256 i = 0; i < myTokens[_account].length; i++) {
            if (!myTokens[_account][i].isWithdrawn) {
                staked++;
            }
        }
        return staked;
    }

    function calculateLiquidityValue(
        iLockedLiquidityPoolToken.LockPeriod _lockPeriod,
        uint256 _numberOfLiquidityPoolTokens
    ) public view returns (uint256) {
        return
            _numberOfLiquidityPoolTokens.mul(
                determineLockPeriodMultiplier(_lockPeriod)
            );
    }

    function determineLockPeriodMultiplier(
        iLockedLiquidityPoolToken.LockPeriod _lockPeriod
    ) public view returns (uint256) {
        if (_lockPeriod == iLockedLiquidityPoolToken.LockPeriod.THREE_MONTHS) {
            return 10;
        } else if (
            _lockPeriod == iLockedLiquidityPoolToken.LockPeriod.SIX_MONTHS
        ) {
            return 25;
        } else if (
            _lockPeriod == iLockedLiquidityPoolToken.LockPeriod.TWELVE_MONTHS
        ) {
            return 75;
        }

        return 0;
    }

    function idsStaked(address account) public view returns (uint256[] memory) {
        uint256[] memory staked = new uint256[](totalStaked(account));
        uint256 tempIdx = 0;
        for (uint256 i = 0; i < myTokens[account].length; i++) {
            if (!myTokens[account][i].isWithdrawn) {
                staked[tempIdx] = myTokens[account][i].id;
                tempIdx++;
            }
        }
        return staked;
    }

    // todo ensure ownership of token
    function stake(uint256 _tokenId) public virtual {
        (
            uint256 lockStart,
            uint256 lockEnd,
            uint256 liquidityPoolTokens,
            iLockedLiquidityPoolToken.LockPeriod lockPeriod
        ) = getToken(_tokenId);

        require(
            lockEnd - 24 hours > block.timestamp,
            "Cover has expired or is 24 hours away from expiring!"
        );

        require(liquidityPoolTokens > 0, "Staked amount must be more than 0");

        uint256 liquidityValue = calculateLiquidityValue(
            lockPeriod,
            liquidityPoolTokens
        );

        myTokens[msg.sender].push(
            LLPNFT(
                _tokenId,
                lockStart,
                lockEnd,
                liquidityPoolTokens,
                liquidityValue,
                false
            )
        );

        countNftStaked = countNftStaked.add(1);

        totalLiquidityPoolTokens = totalLiquidityPoolTokens.add(
            liquidityPoolTokens
        );

        myLiquidityTokens[msg.sender] = myLiquidityTokens[msg.sender].add(
            liquidityPoolTokens
        );

        totalLiquidityValue = totalLiquidityValue.add(liquidityValue);

        myLiquidityValue[msg.sender] = myLiquidityValue[msg.sender].add(
            liquidityValue
        );

        wrappedLiquidityPoolToken.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
    }

    function withdraw(uint256 _tokenId) public virtual {
        for (uint256 i = 0; i < myTokens[msg.sender].length; i++) {
            if (
                myTokens[msg.sender][i].id == _tokenId &&
                !myTokens[msg.sender][i].isWithdrawn
            ) {
                countNftStaked = countNftStaked.sub(1);

                totalLiquidityPoolTokens = totalLiquidityPoolTokens.sub(
                    myTokens[msg.sender][i].liquidityPoolTokens
                );

                myLiquidityValue[msg.sender] = myLiquidityValue[msg.sender].sub(
                    myTokens[msg.sender][i].liquidityPoolTokens
                );

                myTokens[msg.sender][i].isWithdrawn = true;
                wrappedLiquidityPoolToken.transferFrom(
                    address(this),
                    msg.sender,
                    _tokenId
                );
            }
        }
    }

    function withdrawAll() public virtual {
        for (uint256 i = 0; i < myTokens[msg.sender].length; i++) {
            if (!myTokens[msg.sender][i].isWithdrawn) {
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
            iLockedLiquidityPoolToken.LockPeriod
        )
    {
        return wrappedLiquidityPoolToken.getToken(_id);
    }

    struct LLPNFT {
        uint256 id;
        uint256 lockStart;
        uint256 lockEnd;
        uint256 liquidityPoolTokens;
        uint256 liquidityValue;
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
