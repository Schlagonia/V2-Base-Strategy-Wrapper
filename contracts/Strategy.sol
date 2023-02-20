// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BaseStrategyWrapper} from "./StrategyWrapper.sol";

// Import interfaces for many popular DeFi projects, or add your own!
//import "../interfaces/<protocol>/<Interface>.sol";

contract Strategy is BaseStrategyWrapper {
    using SafeERC20 for ERC20;

    constructor(address _asset, address _vault)
        BaseStrategyWrapper(_asset,  "Strategy Example", "tsSTGY", _vault)
    {}

    // NOTE: Should use the 'asset' variable to get the address of the vaults token rather than 'want'

    /** 
    // @dev Should invest up to '_amount' of 'asset' and return the actual amount that was invested
    //      Should do any needed param checks, 0 may get passed in as '_amount'.
    // @param _amount, The amount of 'asset' that should be invested.
    // @return _invested The actual amount of 'asset' that was invested.
    // NOTE: Should not rely on asset.balanceOf(address(this)) calls other than for diff accounting puroposes
    */
    function _invest(uint256 _amount) internal override returns (uint256 _invested) {
        // TODO: implement deposit logice EX: 
        //
        //      uint256 before = ERC20(asset).balanceOf(address(this));
        //      lendingpool.deposit(asset, _amount ,0);
        //      _invested = before - ERC20(asset).balanceOf(address(this));
        _invested = _amount;
    }

    /**
    // @dev Will attempt to free the '_amount' of assets and return the actual amount freed
    //      Should do any needed param checks, '_amount' may be more than is actually available.
    // @param _amount, The amount of 'asset' to be freed up
    // @return _freed The actual amount of 'asset' that was withdrawn.
    // NOTE: Should not rely on asset.balanceOf(address(this)) calls other than for diff accounting puroposes
    // NOTE: The amount of 'asset' that is already loose has already been accounted for
    */
    function _freeFunds(uint256 _amount) internal override returns (uint256 _freed) {
        // TODO: implement withdraw logic EX: 
        //
        //      uint256 before = ERC20(asset).balanceOf(address(this));
        //      lendingPool.withdraw(asset, _amount);
        //      _freed = ERC20(asset).balanceOf(address(this)) - before;
        _freed = _amount;
    }

    /** 
    // @dev Non-view function to return the accurate amount of funds currently invested
    //      Should do any needed accrual, reward selling etc. here before returning the the amount invested
    //      This can leave all assets uninvested if desired as there will always be a _invest() call at the end of the report
    // @return _invested The amount of currently invested funds the strategy has deployed and accrued.
    // NOTE: Should not rely on asset.balanceOf(address(this)) calls other than for diff accounting puroposes
    // NOTE: This should not account for any 'asset' that was loose at the begining of the call. Only the actual funds invested or claimed
    */
    function _totalInvested() internal override returns (uint256 _invested) {
        // TODO: Implement harvesting logic and accurate accounting EX:
        //
        //      uint256 before = ERC20(asset).balanceOf(address(this));
        //      _claminAndSellRewards();
        //      uint256 claimed = ERC20(asset).balanceOf(address(this)) - before;
        //      _invested = aToken.balanceof(address(this)) + claimed;
        _invested = ERC20(asset).balanceOf(address(this));
    }

    // NOTE: Can override `tendTrigger` if necessary. Tends will lead to _invest being called
    // NOTE: Should avoid using `harvestTrigger` if possible, rather adjust maxReportDelay post
    //      deployment for time based harvest cycle
}
 