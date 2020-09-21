pragma solidity ^0.6.0;

interface iLockedLendingPoolToken {
    struct LLPNFT {
        LockPeriod lockPeriod;
        uint256 lockStart;
        uint256 lockEnd;
        uint256 amount;
        bool isEntity;
    }

    enum LockPeriod {
        FINISHED,
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS
    }

    function lockLendingPoolToken(uint256 _amount, LockPeriod _lockPeriod)
        external
        virtual
        returns (uint256);

    function withdraw(uint256 _id) external virtual;

    function getTokenById(uint256 _id)
        external
        virtual
        view
        returns (
            uint256 lockStart,
            uint256 lockEnd,
            uint256 amount,
            bool isEntity,
            LockPeriod lockPeriod
        );
}
