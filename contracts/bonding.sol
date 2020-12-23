// contracts/bonduingContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "hardhat/console.sol";

//import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Token {
  function balanceOf(address addy) external view returns(uint);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function createStreamToBonding(address sender, uint amount) external returns(uint);
  function createStreamFromBonding(address recipient, uint amount, uint duration) external returns(uint);
}

interface SlidingWindowOracle {
    function update(address tokenA, address tokenB) external;
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

interface Shares {
  function balanceOf(address account) external view returns (uint256);
  function mint(address recipient, uint amount) external;
  function burn(address account, uint amount) external;
  function totalSupply() external view returns (uint256);
}


contract bondingContract is Ownable, Initializable {

  using SafeMath for uint;
  Token private _token;
  SlidingWindowOracle private _oracle;
  Shares private _shares;

  uint targetPrice = 1000000000000000000;
  address targetToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC
  address private _couponContract;
  uint private maxBondingPrice = 1000000000000000000000000; //Initially set at $1,000,000 to avoid interference with growth.
  uint private _bondingDiscountMultiplier = 0;
  uint private _rewardsBalance;
  uint private _streamTime = 86400;


//getters
  function getToken() public view returns(address) {
    return address(_token);
  }
  function getOracle() public view returns(address) {
    return address(_oracle);
  }
  function getShares() public view returns(address) {
    return address(_shares);
  }
  function getBondingDiscountMultiplier() public view returns(uint) {
    return _bondingDiscountMultiplier;
  }
  function getRewardsBalance() public view returns(uint) {
    return _rewardsBalance;
  }
  function getCouponContract() public view returns(address) {
    return _couponContract;
  }
  function getStreamTime() public view returns(uint) {
    return _streamTime;
  }

//setters
  function setOracle(address _newOracle) public onlyOwner {
    _oracle = SlidingWindowOracle(_newOracle);
  }
  function setToken(address _newToken) public onlyOwner {
    _token = Token(_newToken);
  }
  function setShares(address _newShares) public onlyOwner {
    _shares = Shares(_newShares);
  }
  function setBondingDiscountMultiplier(uint _newMultiplier) public onlyOwner {
    _bondingDiscountMultiplier = _newMultiplier;
  }
  function setCouponContract(address _newCouponContract) public onlyOwner {
    _couponContract = _newCouponContract;
  }
  function setStreamTime(uint _newStreamTime) public onlyOwner {
    _streamTime = _newStreamTime;
  }

//this method will require multiple revisions to accomodate streaming into bonding. also, would the shares be required to stream out?
  function bondTokens(uint amount) public {
    _oracle.update(address(this), targetToken);
    uint currentPrice = _oracle.consult(address(_token), targetPrice, targetToken);
    require(currentPrice < maxBondingPrice, 'price too high');
    _token.transferFrom(msg.sender, address(this), amount);
    uint shareValue = getCurrentShareValue();
    uint numberOfShares = amount.div(shareValue).mul(targetPrice);
    _rewardsBalance = _rewardsBalance.add(amount);
    if(_bondingDiscountMultiplier != 0) {
      uint bonus = (targetPrice.sub(currentPrice)).mul(numberOfShares).mul(_bondingDiscountMultiplier).div(targetPrice.mul(targetPrice));
      numberOfShares = numberOfShares.add(bonus);
    }
    _shares.mint(msg.sender, numberOfShares);
  }

  function increaseShareValue(uint amount)public {
    require(msg.sender == _couponContract, '!couponContract');
    _rewardsBalance = _rewardsBalance.add(amount);
  }

  function getCurrentShareValue() public view returns(uint pricePerShare) {
    uint totalShares = _shares.totalSupply();
    if(totalShares == 0) return targetPrice;
    pricePerShare = _rewardsBalance.mul(targetPrice).div(totalShares);
  }

  function redeemShares(uint amount) public {
    _oracle.update(address(this), targetToken);
    require(_shares.balanceOf(msg.sender) >= amount, 'not enough shares');
    uint shareValue = getCurrentShareValue();
    _shares.burn(msg.sender, amount);
    uint tokenAmount = amount.mul(shareValue).div(targetPrice);
    _rewardsBalance = _rewardsBalance.sub(tokenAmount);
    _token.createStreamFromBonding(msg.sender, tokenAmount, _streamTime);
  }


}
