// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Create2.sol";

import {SimpleAccount} from "simple-account/src/SimpleAccount.sol";

import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract AccountFactory {
    function deployAccount(IEntryPoint entryPoint, address owner, bytes32 salt) public returns (address) {
        bytes memory bytecode = abi.encodePacked(type(SimpleAccount).creationCode, abi.encode(entryPoint, owner));
        return Create2.deploy(0, salt, bytecode);
    }

    function getAddress(IEntryPoint entryPoint, address owner, bytes32 salt) public view returns (address) {
        bytes32 bytecodeHash =
            keccak256(abi.encodePacked(type(SimpleAccount).creationCode, abi.encode(entryPoint, owner)));
        return Create2.computeAddress(salt, bytecodeHash);
    }
}
