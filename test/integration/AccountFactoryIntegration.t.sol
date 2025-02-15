// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {Test, console2 as console} from "forge-std/Test.sol";

import {AccountFactory} from "src/AccountFactory.sol";

import {SimpleAccount} from "simple-account/src/SimpleAccount.sol";

import {Paymaster} from "simple-paymaster/src/Paymaster.sol";

import {EntryPoint} from "account-abstraction/contracts/core/EntryPoint.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";

contract AccountFactoryIntegration is Test {
    using Bytes for bytes;

    AccountFactory private s_accountFactory;

    Paymaster private s_paymaster;
    EntryPoint private s_entryPoint;

    Account private s_owner;
    Account private s_paymasterOwner;

    function setUp() public {
        s_owner = makeAccount("s_owner");
        s_paymasterOwner = makeAccount("s_paymasterOwner");

        s_entryPoint = new EntryPoint();
        s_accountFactory = new AccountFactory();

        vm.prank(s_paymasterOwner.addr);
        s_paymaster = new Paymaster(s_entryPoint);
    }

    function testFactoryDeploysThroughEntryPoint() public {
        // create receiver
        address receiver = makeAddr("receiver");

        // create bundler
        address bundler = makeAddr("bundler");
        vm.deal(bundler, 10 ether);

        // create salt
        bytes32 salt = keccak256(abi.encode("salt"));

        // get address of account contract
        address sender = s_accountFactory.getAddress(s_entryPoint, s_owner.addr, salt);

        // create userOp
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: sender,
            nonce: 0,
            initCode: hex"",
            callData: hex"",
            accountGasLimits: bytes32(uint256(1_000_000) << 128 | uint256(1_000_000)),
            preVerificationGas: 0,
            gasFees: bytes32(uint256(0) << 128 | uint256(0)),
            paymasterAndData: hex"",
            signature: hex""
        });

        // create initCode
        userOp.initCode = abi.encodePacked(
            address(s_accountFactory),
            abi.encodeWithSelector(AccountFactory.deployAccount.selector, s_entryPoint, s_owner.addr, salt)
        );

        assertEq(keccak256(userOp.initCode.slice(0, 20)), keccak256(abi.encodePacked(address(s_accountFactory))));

        // (bool success, bytes memory data) = address(s_accountFactory).call(userOp.initCode.slice(20));
        // address actualAddress = abi.decode(data, (address));
        // assertEq(sender, actualAddress);

        // add deposit for paymaster
        s_entryPoint.depositTo{value: 10 ether}(address(s_paymaster));

        // create message for paymaster signature
        string memory message = string.concat(
            "Approved paymaster request for ",
            Strings.toHexString(userOp.sender),
            " with ",
            Strings.toString(userOp.nonce),
            " on chain ID ",
            Strings.toString(block.chainid)
        );

        // get signature components
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(s_paymasterOwner.key, keccak256(abi.encodePacked(message)));

        // create paymasterAndData
        userOp.paymasterAndData = abi.encodePacked(
            address(s_paymaster), bytes32(uint256(200_000) << 128 | uint256(200_000)), abi.encodePacked(r, s, v)
        );

        // create callData
        userOp.callData = abi.encodeWithSelector(SimpleAccount.execute.selector, receiver, 1 ether, hex"");

        // get userOpHash
        bytes32 userOpHash = s_entryPoint.getUserOpHash(userOp);

        // get signature components
        (v, r, s) = vm.sign(s_owner.key, userOpHash);

        // add signature to userOp
        userOp.signature = abi.encodePacked(r, s, v);

        // create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);

        userOps[0] = userOp;

        // the userOp execution is going to fail as we are sending eth from account
        // contract which it doesn't have but for testing factory that's okay as
        // main purpose this test is to test if factory deploys new account which it should 

        // check correct event emitted
        vm.expectEmit(true, true, true, false, address(s_entryPoint));
        emit IEntryPoint.UserOperationEvent(userOpHash, sender, address(s_paymaster), 0, false, 0, 0);
        // send userOp to entryPoint
        s_entryPoint.handleOps(userOps, payable(bundler));
    }
}
