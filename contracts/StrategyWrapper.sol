// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity ^0.8.15;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import {BaseStrategy, StrategyParams} from "@yearnvaults/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract BaseStrategyWrapper is BaseStrategy {

    address internal asset;
    string internal _name;
    string public symbol;

    constructor(address _asset, string memory _name_, string memory _symbol, address _vault) BaseStrategy(_vault) {
        require(_asset == address(want), "Wrong token");
        asset = _asset;
        _name = _name_;
        symbol = _symbol;
    }

    // ******** OVERRIDE THESE METHODS IN THE IMPLEMENTATION CONTRACT ************

    
    function _invest(uint256 assets)
        internal
        virtual
        returns (uint256 invested);

    
    function _freeFunds(uint256 amount)
        internal
        virtual
        returns (uint256 withdrawnAmount);

    
    function _totalInvested() internal virtual returns (uint256);


    // ******** OVERRIDE THESE METHODS IN THE IMPLEMENTATION BASE CONTRACT ************

    function name() external view override returns (string memory) {
        return _name;
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return want.balanceOf(address(this));
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 totalAssets = _totalInvested();
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;

        if (totalDebt > totalAssets) {
            // we have losses
            _loss = totalDebt - totalAssets;
        } else {
            // we have profit
            _profit = totalAssets - totalDebt;
        }

        (uint256 _amountFreed, ) = liquidatePosition(_debtOutstanding + _profit);
            
        _debtPayment = Math.min(_debtOutstanding, _amountFreed);
            
        //Adjust profit in case we had any losses from liquidatePosition
        _profit = _amountFreed - _debtPayment;   
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 looseWant = want.balanceOf(address(this));
        
        // we still should call invest even if 0 for potential tend calls
        _invest(looseWant > _debtOutstanding ? looseWant - _debtOutstanding : 0);

    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 looseWant = want.balanceOf(address(this));

        if(looseWant < _amountNeeded) {
            _freeFunds(_amountNeeded - looseWant);
        }

        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            unchecked {
                _loss = _amountNeeded - totalAssets;
            }
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _freeFunds(type(uint256).max);
        return want.balanceOf(address(this));
    }

    

    function prepareMigration(address _newStrategy) internal override {
        _freeFunds(type(uint256).max);
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistent* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // TODO create an accurate price oracle
        return _amtInWei;
    }
}
