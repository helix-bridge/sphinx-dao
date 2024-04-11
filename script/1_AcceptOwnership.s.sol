// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base} from "./common/Base.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

interface III {
    function dao() external view returns (address);
    function pendingDao() external view returns (address);
    function acceptOwnership() external;
}

contract AcceptOwnership1 is Base {
    address HelixBridge = 0xbA5D580B18b6436411562981e02c8A9aA1776D10;

    function run() public sphinx {
        address dao = safeAddress();
        safeconsole.log("dao:", dao);
		revert();
        if (dao == III(HelixBridge).pendingDao()) {
            III(HelixBridge).acceptOwnership();
        }
    }
}
