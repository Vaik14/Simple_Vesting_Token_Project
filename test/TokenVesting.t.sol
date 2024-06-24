// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Test, console} from "forge-std/Test.sol";
import {TokenVesting} from "../src/TokenVesting.sol";
import {Token} from "../src/Token.sol";
import {DeployToken} from "../script/DeployToken.s.sol";

contract TokenVestingTest is Test {
    Token public token;

    TokenVesting public tokenVesting;

    function setUp() public {
        DeployToken deployerToken = new DeployToken();
        token = deployerToken.run();
        tokenVesting = new TokenVesting(address(token));
    }

    function testAddVestingTeamAddress() public {
        address team = makeAddr("team");
        vm.startPrank(tokenVesting.s_owner());
        tokenVesting.addVestingAddressTeam(team);
    }

    function testAddVestingTeamAddressFail() public {
        vm.startPrank(tokenVesting.s_owner());
        vm.expectRevert();
        tokenVesting.addVestingAddressTeam(address(0));
    }

    function testAddVestingTeamAddressCallingTwice() public {
        vm.startPrank(tokenVesting.s_owner());
        address team = makeAddr("team");
        tokenVesting.addVestingAddressTeam(team);
        address team2 = makeAddr("team2");
        vm.expectRevert();
        tokenVesting.addVestingAddressTeam(team2);
    }

    function testCheckMintableTeamFunds()public {
        (uint256 startTime,
        uint256 lockTime,
        uint256 endTime,
        uint256 totalAllocationAmount,
        uint256 mintedAmount,
        uint256 withdrawableAmountInContract,
        uint256 transferedAmount,
        address assignedAddress)  = tokenVesting.VestingDetailsTeam();
        console.log("startTime",startTime);
        console.log("lockTime",lockTime);
        console.log("endTime",endTime);
        console.log("totalAllocationAmount",totalAllocationAmount);
        console.log("mintedAmount",mintedAmount);
        console.log("withdrawableAmountInContract",withdrawableAmountInContract);
        console.log("transferedAmount",transferedAmount);
        console.log("assignedAddress",assignedAddress);

        uint256 mintableTokens = tokenVesting.checkMintableTeamFunds();
        console.log("mintableTokens",mintableTokens);
        vm.warp(182 days);         
        mintableTokens = tokenVesting.checkMintableTeamFunds();
        console.log("mintableTokens",mintableTokens);
        vm.warp(183 days);         
        uint256 mintableTokens2 = tokenVesting.checkMintableTeamFunds();
        console.log("mintableTokens2",mintableTokens2);
        // testing equal number of tokens are available to mint everyday
        assertEq(mintableTokens,(mintableTokens2 - mintableTokens));

    }

    function testMintTeamRewardsOnlyOwnerCanCall()public {
        vm.startPrank(tokenVesting.s_owner());
        address team = makeAddr("team");
        tokenVesting.addVestingAddressTeam(team);
        vm.warp(182 days);         
        uint256 mintableTokens = tokenVesting.checkMintableTeamFunds();
        console.log("mintableTokens",mintableTokens);
        // not calling with owner address
        address caller = makeAddr("caller");
        vm.startPrank(caller);
        vm.expectRevert();
        tokenVesting.mintTeamRewards(mintableTokens);
    }

    function testMintTeamRewards()public {
        vm.startPrank(token.owner());
        token.transferOwnership(address(tokenVesting));
        vm.startPrank(tokenVesting.s_owner());
        address team = makeAddr("team");
        tokenVesting.addVestingAddressTeam(team);
        vm.warp(182 days);         
        uint256 mintableTokens = tokenVesting.checkMintableTeamFunds();
        console.log("mintableTokens",mintableTokens);
        tokenVesting.mintTeamRewards(mintableTokens);
        console.log(token.balanceOf(address(tokenVesting)));
    }

    function testTransferTeamFundsToAddress() public{
       vm.startPrank(token.owner());
        token.transferOwnership(address(tokenVesting));
        vm.startPrank(tokenVesting.s_owner());
        address team = makeAddr("team");
        tokenVesting.addVestingAddressTeam(team);
        vm.warp(182 days);         
        uint256 mintableTokens = tokenVesting.checkMintableTeamFunds();
        console.log("mintableTokens",mintableTokens);
        tokenVesting.mintTeamRewards(mintableTokens);
        console.log("Vesting Contract Bal =>",token.balanceOf(address(tokenVesting)));
        (,,,,
        uint256 mintedAmount,
        uint256 withdrawableAmountInContract,
        ,
        address assignedAddress)  = tokenVesting.VestingDetailsTeam();
        console.log("mintedAmount",mintedAmount);
        console.log("withdrawableAmountInContract",withdrawableAmountInContract);
        console.log("assignedAddress",assignedAddress);
        tokenVesting.transferTeamFundsToAddress(withdrawableAmountInContract);
        console.log("assignedAddress Bal =>",token.balanceOf(assignedAddress));
          console.log("Vesting Contract Bal =>",token.balanceOf(address(tokenVesting)));
        console.log("mintedAmount",mintedAmount);
         console.log("withdrawableAmountInContract",withdrawableAmountInContract);
       

        }

}
