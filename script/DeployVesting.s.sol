// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {TokenVesting} from "../src/TokenVesting.sol";

contract DeployVesting is Script{
    Token public token;
    TokenVesting public vesting;


    // function run()public returns(TokenVesting) {
    //     token = new Token();
    //     address tokenAddress = address(token);
    //     vesting = new Vesting(tokenAddress);
    //     return vesting;
    // }
}