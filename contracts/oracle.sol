// contracts/bonduingContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


import "hardhat/console.sol";


//import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PriceOracle {

  using SafeMath for uint;


  function update(address tokenA, address tokenB) external {

  }
  function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
    amountOut = 980000000000000000;
  }


/*
  struct Price {
    uint timestamp;
    uint price;
  }

  mapping(uint => Price) private _prices;
  uint private _firstTimestamp;
  uint private _mostRecentTimestamp;
  uint private _nextPriceIndex;

  constructor() public {
    _firstTimestamp = block.timestamp;
    _nextPriceIndex = 1;
    storePrice(67012345678,65512345678);
  }

  function getCurrentPrice() public view returns(uint) {
    return getPrice(block.timestamp);
  }

  function getCurrentTime() public view returns(uint) {
    return block.timestamp;
  }

  function getPrice(uint _timestamp) public view returns(uint) {
    uint index = _nextPriceIndex.sub(1);
    if(_prices[index].timestamp.sub(_timestamp) <= 3600) return _prices[index].price;
    while(_prices[index].timestamp > _timestamp) index--;
    uint timeBefore = _timestamp.sub(_prices[index].timestamp);
    uint priceBefore = _prices[index].price;
    uint timeAfter = _prices[index.add(1)].timestamp.sub(_timestamp);
    uint priceAfter = _prices[index.add(1)].price;
    uint timeTotal = timeAfter.add(timeBefore);
    uint interpCumlPrice = timeBefore.mul(priceBefore).add(timeAfter.mul(priceAfter));
    return interpCumlPrice.div(timeTotal);
  }
//instead of this function taking arguments, these prices will be brought in from the outside
//price uinits currently in $1/1000000
  function storePrice(uint _ethUSDPrice, uint _ethTokenPrice) public returns(bool){
    require(block.timestamp >= _mostRecentTimestamp.add(3600), 'too soon');
    _mostRecentTimestamp = block.timestamp;
    uint ethUSDprice = _ethUSDPrice.mul(1000000); //in millionths
    _prices[_nextPriceIndex].price = ethUSDprice.div(_ethTokenPrice);
    _prices[_nextPriceIndex].timestamp = _mostRecentTimestamp;
    _nextPriceIndex++;
    console.log(block.timestamp);
    return true;
  }
*/
}
