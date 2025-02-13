// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {Test, console2 as console} from "forge-std/Test.sol";

import {AccountFactory} from "src/AccountFactory.sol";

import {SimpleAccount} from "simple-account/src/SimpleAccount.sol";

import {EntryPoint} from "account-abstraction/contracts/core/EntryPoint.sol";

contract AccountFactoryTest is Test {
    AccountFactory private s_accountFactory;
    EntryPoint private s_entryPoint;

    function setUp() public {
        s_accountFactory = new AccountFactory();
        s_entryPoint = new EntryPoint();
    }

    function testAccountIsDeployedFromFactory() public {
        address owner = makeAddr("owner");
        bytes32 salt = keccak256(abi.encode("salt"));

        address accountAddress = s_accountFactory.deployAccount(s_entryPoint, owner, salt);
        
        assertEq(accountAddress, s_accountFactory.getAddress(s_entryPoint, owner, salt));
        assertEq(SimpleAccount(accountAddress).owner(), owner);
    }
}
