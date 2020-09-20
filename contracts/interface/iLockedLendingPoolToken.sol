pragma solidity ^0.6.0;

interface iLockedLendingPoolToken {
    struct LLPNFT {
        uint256 lockStart;
        uint256 lockEnd;
        uint256 amount;
        bool isEntity;
    }

    function lockLendingPoolToken(uint256 _amount, uint256 _duration)
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
            bool isEntity
        );
}
