// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./GenericLenderBase.sol";

abstract contract GenericLenderAdapter is GenericLenderBase {
    using Address for address;
    using SafeERC20 for IERC20;

    address public asset;
    string public symbol;
    address public keeper;

    modifier onlyKeepers() {
        require(
            msg.sender == address(keeper) ||
                msg.sender == address(strategy) ||
                msg.sender == vault.governance() ||
                msg.sender == IBaseStrategy(strategy).strategist(),
            "!keepers"
        );
        _;
    }

    // add a only mangement modifier

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _strategy
    ) GenericLenderBase(_strategy, _name) {
        require(_asset == address(want), "wrong token");
        asset = _asset;
        symbol = _symbol;
    }

    function setKeeper(address _keeper) external management {
        keeper = _keeper;
    }

    function withdraw(uint256 amount)
        external
        override
        management
        returns (uint256)
    {
        uint256 total = _nav();
        uint256 looseBalance = want.balanceOf(address(this));

        if (amount > total) {
            //cant withdraw more than we own
            amount = total;
        }

        if (looseBalance >= amount) {
            want.safeTransfer(address(strategy), amount);
            return amount;
        }

        _freeFunds(amount - looseBalance);

        looseBalance = want.balanceOf(address(this));
        want.safeTransfer(address(strategy), looseBalance);
        return looseBalance;
    }

    //emergency withdraw. sends balance plus amount to governance
    //Pass in uint256.max to withdraw everything
    function emergencyWithdraw(uint256 amount)
        external
        override
        onlyGovernance
    {
        //dont care about errors here. we want to exit what we can
        _freeFunds(amount);

        want.safeTransfer(vault.governance(), want.balanceOf(address(this)));
    }

    function deposit() external override management {
        uint256 balance = want.balanceOf(address(this));
        _invest(balance, true);
    }

    function withdrawAll() external override management returns (bool) {
        uint256 invested = _nav();
        _freeFunds(invested);
        uint256 returned = want.balanceOf(address(this));
        return returned >= invested;
    }

    function hasAssets() external view override returns (bool) {
        return _nav() > dust;
    }

    function aprAfterDebtChange(int256 delta)
        public
        view
        virtual
        returns (uint256)
    {}

    function nav() external view override returns (uint256) {
        return _nav();
    }

    function _nav() internal view virtual returns (uint256) {}

    function apr() external view override returns (uint256) {
        return _apr();
    }

    function _apr() internal view returns (uint256) {
        return aprAfterDebtChange(0);
    }

    function aprAfterDeposit(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        aprAfterDebtChange(int256(amount));
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
        protected[0] = address(want);
        return protected;
    }

    // ******** OVERRIDE THESE METHODS IN THE IMPLEMENTATION CONTRACT ************ \\

    /*//////////////////////////////////////////////////////////////
                    NEEDED TO OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    function _invest(uint256 assets, bool _reported) internal virtual;

    function _freeFunds(uint256 amount) internal virtual;

    function _totalInvested() internal virtual returns (uint256);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    function _tend() internal virtual {}

    function maxDeposit(address _owner)
        external
        view
        virtual
        returns (uint256)
    {
        return type(uint256).max;
    }

    function maxMint(address _owner) external view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address _owner)
        external
        view
        virtual
        returns (uint256)
    {
        return vault.strategies(address(this)).totalDebt;
    }

    function maxRedeem(address _owner) external view virtual returns (uint256) {
        return vault.strategies(address(this)).totalDebt;
    }
}
