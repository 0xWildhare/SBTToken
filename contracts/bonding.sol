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
  function createStreamToBonding(address sender, uint amount, uint duration) external returns(uint);
  function createStreamFromBonding(address recipient, uint amount, uint duration) external returns(uint);
  function getStream(uint256 streamId)
    external
    view
    returns (
        address sender,
        address recipient,
        uint256 amount,
        uint256 startTime,
        uint256 stopTime,
        uint256 remainingBalance,
        uint256 ratePerSecond
    );
  function updateStream(uint streamId) external;
  function getStreamIndicies(address _address) external view returns(uint[5] memory);
  function cancelStream(uint _streamId) external;
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
  uint private _maxBondingPrice = 1000000000000000000000000; //Initially set at $1,000,000 to avoid interference with growth.
  uint private _bondingDiscountMultiplier = 0;
  uint private _rewardsBalance;
  uint private _redeemStreamTime = 86400; //initially set at 1 week
  uint private _bondStreamTime = 0; //initially set at 0 (instant)


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
  function getRedeemStreamTime() public view returns(uint) {
    return _redeemStreamTime;
  }
  function getBondStreamTime() public view returns(uint) {
    return _bondStreamTime;
  }
  function getMaxBondingPrice() public view returns(uint) {
    return _maxBondingPrice;
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
  function setRedeemStreamTime(uint _newRedeemStreamTime) public onlyOwner {
    _redeemStreamTime = _newRedeemStreamTime;
  }
  function setBondStreamTime(uint _newBondStreamTime) public onlyOwner {
    _bondStreamTime = _newBondStreamTime;
  }
  function setMaxBondingPrice(uint _newMaxBondingPrice) public onlyOwner {
    _maxBondingPrice = _newMaxBondingPrice;
  }

  function bondTokens(uint amount) public {
    _oracle.update(address(this), targetToken);
    uint currentPrice = _oracle.consult(address(_token), targetPrice, targetToken);
    require(currentPrice < _maxBondingPrice, 'price too high');
    if(_bondStreamTime == 0 ) _token.transferFrom(msg.sender, address(this), amount);
    else _token.createStreamToBonding(msg.sender, amount, _bondStreamTime);
    _bond(amount);
  }
  function _bond(uint amount) internal {
    uint shareValue = getCurrentShareValue();
    uint numberOfShares = amount.div(shareValue).mul(targetPrice);
    _rewardsBalance = _rewardsBalance.add(amount);
    if(_bondingDiscountMultiplier != 0) {
      uint currentPrice = _oracle.consult(address(_token), targetPrice, targetToken);
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
    uint tokenAmount = amount.mul(shareValue).div(targetPrice);
    _rewardsBalance = _rewardsBalance.sub(tokenAmount);
    _shares.burn(msg.sender, amount);
    if(_redeemStreamTime == 0 ) _token.transferFrom(address(this), msg.sender, amount);
    else _token.createStreamFromBonding(msg.sender, tokenAmount, _redeemStreamTime);
  }

  function redeemAllShares() public {
    redeemShares(_shares.balanceOf(msg.sender));
  }

  function cancelRedeemStream() public {
    _oracle.update(address(this), targetToken);
    uint[5] memory streams = _token.getStreamIndicies(msg.sender);
    uint index = streams[3];
    require(index != 0, 'no stream');
    _token.updateStream(index);
    (,,,,,uint amount,) = _token.getStream(index);
    _token.cancelStream(index);
    _bond(amount);
  }

  function cancelBondStream() public {
    _oracle.update(address(this), targetToken);
    uint[5] memory streams = _token.getStreamIndicies(msg.sender);
    uint index = streams[2];
    require(index != 0, 'no stream');
    _token.updateStream(index);
    (,,,,,uint remainingBalance,) = _token.getStream(index);
    _rewardsBalance = _rewardsBalance.sub(remainingBalance);
    uint shareValue = getCurrentShareValue();
    uint unpaidShares = remainingBalance.div(shareValue).mul(targetPrice);
    _shares.burn(msg.sender, unpaidShares);
    _token.cancelStream(index);
  }


}
