// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract LnBridgeV3OwnerChecker11 is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();
        checkProxyAdminOwner();
        checkBridgeOwner();
        checkMessagerOwner();
    }
}
