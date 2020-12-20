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

interface Token {
  function balanceOf(address addy) external view returns(uint);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function createStreamToBonding(address sender, uint amount) external returns(uint);
}

interface IUniswapV2Pair {
   function price0CumulativeLast() external view returns (uint);
}

contract bondingContract is Ownable, Initializable {

  using SafeMath for uint;
  Token private _token;
  IUniswapV2Pair private _pair;
  uint nextDepositIndex;
  uint private _interestDivisor = 1000; //this is only needed if we are compounding
  uint private _interestMultiplier = 1000; //don't know if we need this either
  uint target = 1000000000000000000;

  struct Deposit {
    uint amount;
    uint priceCumulativeAtDeposit;
    uint timestamp;
    uint streamIndex;
    bool isEntity;
  }

  mapping(uint => Deposit) private _deposits;
  mapping(address => uint) private _depositIndex;

  constructor()public {
    nextDepositIndex = 1;
  }

  function getToken() public view returns(address) {
    return address(_token);
  }
  function getPair() public view returns(address) {
    return address(_pair);
  }
  function getDivisor() public view returns(uint) {
    return _interestDivisor;
  }
  function getMultiplier() public view returns(uint) {
    return _interestMultiplier;
  }

  function setPair(address _newPair) public onlyOwner {
    _pair = IUniswapV2Pair(_newPair);
  }
  function setToken(address _newToken) public onlyOwner {
    _token = Token(_newToken);
  }
  function setDivisor(uint _newDivisor) public onlyOwner {
    _interestDivisor = _newDivisor;
  }
  function setMultiplier(uint _newMultiplier) public onlyOwner {
    _interestMultiplier = _newMultiplier;
  }

  function getBondingBalance() public view returns(uint) {
    return _token.balanceOf(address(this));
  }

  function bondTokens(uint amount) public {
    require(_depositIndex[msg.sender] == 0, "has existing stream");
    uint streamIndex = _token.createStreamToBonding(msg.sender, amount);
    uint index = nextDepositIndex;
    _deposits[index].amount = amount;
    _deposits[index].timestamp = block.timestamp;
    _deposits[index].priceCumulativeAtDeposit = _pair.price0CumulativeLast(); //dont know if this will be price0Cumulative or price1cumulative
    _deposits[index].streamIndex = streamIndex;
    _deposits[index].isEntity = true;
    _depositIndex[msg.sender] = index;
    nextDepositIndex++;
  }

  function getCurrentValue(uint index) public view returns(uint) {
    uint duration = block.timestamp.sub(_deposits[index].timestamp);
    if(duration == 0) return _deposits[index].amount;


    /*
    require(_deposits[index].isEntity, "no deposit");
    uint amount = _deposits[index].amount;
    uint timestamp = _deposits[index].timestamp;
    uint intrestRate;
    uint intrest;
    uint intrestInMillionths;
    uint time = block.timestamp.sub(timestamp);
    if(time <= 3600){
      intrestRate = _getIntrestRate(timestamp);
      intrestInMillionths = amount.mul(intrestRate).mul(time).div(3600);
      intrest = intrestInMillionths.div(1000000);
      return amount.add(intrest);
    }
    while(timestamp.add(3600) < block.timestamp){
      intrestRate = _getIntrestRate(timestamp);
      intrest = amount.mul(intrestRate).div(1000000);
      console.log(intrest);
      amount = amount.add(intrest);
      timestamp = timestamp.add(3600);
    }
    if(timestamp == block.timestamp) return amount;
    intrestRate = _getIntrestRate(timestamp);
    time = block.timestamp.sub(timestamp);
    intrestInMillionths = amount.mul(intrestRate).mul(time).div(3600);
    intrest = intrestInMillionths.div(1000000);
    console.log(intrest);
    return amount.add(intrest);
    */
  }

  function updateDeposit(uint index) public {
    _deposits[index].amount = getCurrentValue(index);
    _deposits[index].timestamp = block.timestamp;
  }

  //the intrest rate is in unitsw of 1/1000000
  function _getIntrestRate(uint index) internal view returns(uint) {
    uint twap = _getTwap(index);
    if(twap <= target){
      uint intrestRate = twap.sub(target);
      uint intrestAdjusted = intrestRate.mul(_interestMultiplier).div(_interestDivisor);
    }
  }

  function _getTwap(uint index) internal view returns(uint) {
    uint duration = block.timestamp.sub(_deposits[index].timestamp);
    if(duration == 0) return 0;
    uint cumulativePrice = _pair.price0CumulativeLast().sub(_deposits[index].priceCumulativeAtDeposit);
    uint twap = cumulativePrice.div(duration);
    return twap;
  }

  function getIndex() public view returns(uint) {
    uint index = _depositIndex[msg.sender];
    return index;
  }

  function getDeposit() public view returns(
    uint amount,
    uint timestamp,
    bool isEntity
    ) {
      uint index = _depositIndex[msg.sender];
      require(index != 0, 'no deposit');
      amount = _deposits[index].amount;
      timestamp = _deposits[index].timestamp;
      isEntity = _deposits[index].isEntity;
  }



}
