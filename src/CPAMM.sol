// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 totalSupply;
    uint256 reserve0;
    uint256 reserve1;
    mapping(address => uint256) public balance;

    error InvalidToken();

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _updateReserves(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function _mint(address _to, uint256 _amount) private {
        balance[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        balance[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _minimum(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        if (_tokenIn != address(token0) && _tokenIn != address(token1)) revert InvalidToken();
        require(_amountIn > 0, "invalid input");

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) =
            isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        uint256 amountInWithFees = (_amountIn * 997) / 1000;

        // Y*dx/(X+dx)
        amountOut = (reserveOut * amountInWithFees) / (reserveIn + amountInWithFees);

        tokenOut.transfer(msg.sender, amountOut);
        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function addLiquidity(uint256 _amount0, uint256 _amount1) external returns (uint256 shares) {
        require(_amount0 > 0 && _amount1 > 0, "invalid input");
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "dy/dx != Y/X");
            //dy/dx = Y/X
        }

        // shares = (dx/X)*T
        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _minimum((_amount0 * totalSupply) / reserve0, (_amount1 * totalSupply) / reserve1);
        }
        _mint(msg.sender, shares);

        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function removeLiquidity(uint256 _shares) external returns (uint256 amount0, uint256 amount1) {
        require(_shares > 0, "invalid input");

        amount0 = (reserve0 * _shares) / totalSupply;
        amount1 = (reserve1 * _shares) / totalSupply;
        //dx = (s/T)*X
        //dy = (s/T)*Y

        require(amount0 > 0 && amount1 > 0, "amount must be greater than zero");

        _burn(msg.sender, _shares);
        _updateReserves(reserve0 - amount0, reserve1 - amount1);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }
}
