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


contract couponContract is ERC1155, Owanable, Initializable, ReentrancyGuard {

    using SafeMath for uint256;

    uint public nextCouponIndex;
    uint private _duration = 2500;

    struct Coupon {
      uint startTime
      uint expirationTime,
      bool isEntity,

    }

    mapping(uint => Coupon) private _coupons;

    function initialize() public initializer {
      nextCouponIndex = 1;
    }

    function getCoupon(uint _id) public view returns(
      uint startTime
      uint expirationTime,
      bool isEntity,
      )
      {
        startTime = _coupons[_id].startTime;
        expirationTime = _coupons[_id].expirationTime;
        isEntity = _coupons[_id].isEntity;
      }

      function createCoupon()public onlyOwner returns(uint) {
        uint _id = nextCouponIndex;
        nextCouponIndex++;
        coupons[_id] = Coupon({
          startTime: block.timeStamp,
          expirationTime: (block.timestamp.add(_duration)),
          isEntity: true
          })
          return(_id);
      }

      function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        require(streams[id].isEntity);
        _mint(acccount, id, amount, data);
      }

      



}
