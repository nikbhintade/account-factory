// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Create2.sol";

import {console2 as console} from "forge-std/console2.sol";

import {SimpleAccount} from "simple-account/src/SimpleAccount.sol";

import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract AccountFactory {
    function deployAccount(IEntryPoint entryPoint, address owner, bytes32 salt) public returns (address) {
        console.log("deployAccount was called");
        bytes memory bytecode = abi.encodePacked(type(SimpleAccount).creationCode, abi.encode(entryPoint, owner));
        // console.logBytes(bytecode);
        address accountContract = Create2.deploy(0, salt, bytecode);
        console.log("address of newly deployed contract");
        console.log(accountContract);
        return accountContract;
    }

    function getAddress(IEntryPoint entryPoint, address owner, bytes32 salt) public view returns (address) {
        bytes32 bytecodeHash =
            keccak256(abi.encodePacked(type(SimpleAccount).creationCode, abi.encode(entryPoint, owner)));
        return Create2.computeAddress(salt, bytecodeHash);
    }
}
