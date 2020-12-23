// contracts/bLSD.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract bLSD is Ownable, ERC20 {

  address private bondingContract;

    constructor() public ERC20("bondedLSD", "bLSD") {
    }

    function getBondingContract() public view returns(address) {
      return bondingContract;
    }

    function setBondingContract(address _newBondingContract) public onlyOwner {
      bondingContract = _newBondingContract;
    }

    function mint(address recipient, uint amount) public {
      require(msg.sender == bondingContract, '!bondingContract');
      _mint(recipient, amount);
    }

    function burn(address account, uint amount) public {
      require(msg.sender == bondingContract, '!bondingContract');
      _burn(account, amount);
    }


}
