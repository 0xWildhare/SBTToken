// contracts/bonduingContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

//import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

interface Token {
  function balanceOf(address addy) external view returns(uint);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  //TODO add Stream instead.
}

interface Oracle {
  function getPriceDelta() external view returns(uint);
}

contract bondingContract is Ownable, Initializable {

  using SafeMath for uint;
  Token private _token;
  Oracle private _oracle;
  uint nextDepositIndex;
  uint intrestMultiplier = 8;

  struct Deposit {
    uint amount;
//    uint tokenPriceAtDeposit;
    uint timestamp;
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
  function getOracle() public view returns(address) {
    return address(_oracle);
  }


  function setOracle(address _newOracle) public onlyOwner {
    _oracle = Oracle(_newOracle);
  }

  function setToken(address _newToken) public onlyOwner {
    _token = Token(_newToken);
  }

  function getBondingBalance() public view returns(uint) {
    return _token.balanceOf(address(this));
  }

  function bondTokens(uint amount) public {
    _token.transferFrom(msg.sender, address(this), amount);
    uint index = _depositIndex[msg.sender];
    if(index == 0){
      index = nextDepositIndex;
      _deposits[index].amount = amount;
      //  _deposits[msg.sender].tokenPriceAtDeposit = 123456;
      _deposits[index].timestamp = block.timestamp;
      _deposits[index].isEntity = true;
      _depositIndex[msg.sender] = index;
      nextDepositIndex++;
    }
    else{
      uint currentDepositValue = getCurrentValue(index);
      _deposits[index].amount = amount.add(currentDepositValue);
      //  _deposits[msg.sender].tokenPriceAtDeposit = 123456;
      _deposits[index].timestamp = block.timestamp;
      _deposits[index].isEntity = true;
    }
  }

  function getCurrentValue(uint index) public view returns(uint) {
    require(index != 0, "0");
    uint delta = _oracle.getPriceDelta();
    uint intrestRate = intrestMultiplier.mul(delta); //this isn't going to work...
    return _deposits[index].amount.mul(intrestRate);
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
