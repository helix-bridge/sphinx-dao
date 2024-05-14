// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract AcceptOwnership5 is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();
        acceptOwnership();
    }
}
