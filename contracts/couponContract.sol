// contracts/couponContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";


interface Token {
  function balanceOf(address addy) external view returns(uint);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
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
  function mint(uint amount) external;
  function approve(address spender, uint256 amount) external returns (bool);
}

interface Bonding {
  function increaseShareValue(uint amount)external;
}

contract couponContract is  Ownable {

    using SafeMath for uint256;

    uint public nextCouponIndex;
    uint private _duration = 2500;
    Bonding public bonding;
    Token public token;


    function setBonding(address _newBonding) public onlyOwner {
      bonding = Bonding(_newBonding);
    }

    function setToken(address _newToken) public onlyOwner {
      token = Token(_newToken);
    }

//temp for testine
function payBonding(uint amount) public onlyOwner{
  token.mint(amount);
  token.transfer(address(bonding), amount);
  bonding.increaseShareValue(amount);
}




    struct Coupon {
      uint startTime;
      uint expirationTime;
      bool isEntity;
    }

    mapping(uint => Coupon) private _coupons;
/*
    function initialize() public initializer {
      nextCouponIndex = 1;
    }
*/
    function getCoupon(uint _id) public view returns(
      uint startTime,
      uint expirationTime,
      bool isEntity
      )
      {
        startTime = _coupons[_id].startTime;
        expirationTime = _coupons[_id].expirationTime;
        isEntity = _coupons[_id].isEntity;
      }

      function createCoupon()public onlyOwner returns(uint) {
        uint _id = nextCouponIndex;
        nextCouponIndex++;
        _coupons[_id] = Coupon({
          startTime: block.timestamp,
          expirationTime: (block.timestamp.add(_duration)),
          isEntity: true
          });
          return(_id);
      }
/*
      function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        require(streams[id].isEntity);
        _mint(acccount, id, amount, data);
      }
*/




}
