// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract ValidateTokens7 is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();
        string[4] memory tokens = [
            "usdt",
            "usdc",
            "ring",
            "usdb"
        ];
        for (uint idx = 0; idx < tokens.length; idx++) {
            checkTokenAddressOnChain(tokens[idx]);
        }
    }
}
