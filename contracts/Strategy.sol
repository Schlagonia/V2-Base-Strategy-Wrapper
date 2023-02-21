// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import {BaseStrategyAdapter, ERC20} from "./BaseStrategyAdapter.sol";

// Import interfaces for many popular DeFi projects, or add your own!
//import "../interfaces/<protocol>/<Interface>.sol";

contract Strategy is BaseStrategyAdapter {
    constructor(address _asset, address _vault)
        BaseStrategyAdapter(_asset, "Strategy Example", "tsSTGY", _vault)
    {}

    // NOTE: Should use the 'asset' variable to get the address of the vaults token rather than 'want'

    // NOTE: To implement permissioned functions you can use the onlyManagement and onlyKeepers modifiers

    /** 
    // @dev Should invest up to '_amount' of 'asset' and return the actual amount that was invested
    //      Should do any needed param checks, 0 may get passed in as '_amount'.
    //      The _reported bool can be used for sandwhichable strategies, if true you chould expect for
    //      the call to come through a protected relay therefore safe to do swaps etc.
    // @param _amount, The amount of 'asset' that should be invested.
    // @param _reported, Bool repersenting if this is a post report _invest call
    */
    function _invest(uint256 _amount, bool _reported) internal override {
        // TODO: implement deposit logice EX:
        //
        //      lendingpool.deposit(asset, _amount ,0);
    }

    /**
    // @notice Will attempt to free the '_amount' of 'asset'
    // @dev Should do any needed param checks, '_amount' may be more than is actually available.
    //      Should not rely on asset.balanceOf(address(this)) calls other than for diff accounting puroposes
    // NOTE: The amount of 'asset' that is already loose has already been accounted for
    // @param _amount, The amount of 'asset' to be freed up
    */
    function _freeFunds(uint256 _amount) internal override {
        // TODO: implement withdraw logic EX:
        //
        //      lendingPool.withdraw(asset, _amount);
    }

    /** 
    // @notice Should return the accurate amount of funds the strategy currently holds
    // @dev Kept as non view so it can do any needed accrual, reward selling etc. here before returning the the total.
    //      This can leave any or all assets uninvested if desired as there will always be a _invest() call at the end of the report
    // NOTE: This should account for loose 'asset'.
    // @return _invested A non-manipulatable total of all assets the strategy holds in term of 'asset'.
    */
    function _totalInvested() internal override returns (uint256 _invested) {
        // TODO: Implement harvesting logic and accurate accounting EX:
        //
        //      _claminAndSellRewards();
        //      _invested = aToken.balanceof(address(this)) + ERC20(asset).balanceOf(address(this));
        _invested = ERC20(asset).balanceOf(address(this));
    }

    // NOTE: Can override `tendTrigger` if desired. Tends will lead to _invest being called with the adapter but
    //      will lead to a _tend() call in the V3 version

    // NOTE: Should avoid overriding `harvestTrigger` if possible, rather adjust maxReportDelay post
    //      deployment for time based harvest cycle which is how V3 should operate

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
    // NOTE: These function can be overriden to make compliant with V3 but will not be ever called with the V2 adapter

    // @notice Internal function to compound gains or provide maintence to the position
    // @dev Optional function that should simply realize profits to compound between reports
    //      This will do no accounting and have no effect on any pps of the vault till report() is called.
    //      Will need to override tendTrigger() for this to ever be called
    // NOTE: This should not reinvest any amount of 'asset' that is loose at the begining of the call
    function _tend() internal override {}


    // NOTE: these functions are to give strategists the ability to override them for high risk or illiquid strategies.
    //      If withdraws can be sandwhiched maxWithdraw and maxRedeem can return 0 to become illiquid.
    //      Can override maxDeposit() or maxMint() to put a limit on the amount of assets that can be controlled by the strat.
    //      The default implementation in V3 for these returns max uint256 for maxDeposit() and maxMint(). And uses the ERC20 balanceOf() and
    //      the ERC4626 convertToShares() for maxWithdraw() and maxRedeem(). 
    
    // The max amount in terms of 'asset' than can be currently deposited by '_owner'.
    function maxDeposit(
        address _owner
    ) external view override returns (uint256) {}

    // The max amount of shares that can currently be minted by '_owner'.
    function maxMint(
        address _owner
    ) external view override returns (uint256) {}

    // The max amount of 'asset' that can currently be withdrawn by '_owner'.
    function maxWithdraw(
        address _owner
    ) external view override returns (uint256) {}

    // The max amount of shares that can currently be redeemed by '_owner'.
    function maxRedeem(
        address _owner
    ) external view override returns (uint256) {}
    */
}
