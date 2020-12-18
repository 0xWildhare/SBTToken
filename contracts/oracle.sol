// contracts/bonduingContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

//import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PriceOracle {

  using SafeMath for uint;

  function getPriceDelta() external view returns(uint) {
    return 100000000000000000;
  }
}
