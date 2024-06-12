// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract UpgradeMsgport8 is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();

        uint256 CHAINID_CRAB = chainName2chainId["crab"];
        uint256 CHAINID_DARWINIA = chainName2chainId["darwinia"];
        
        // connect networks
        if (block.chainid == CHAINID_CRAB || block.chainid == CHAINID_DARWINIA) {
            messagerAcceptOwnership(MessagerType.MsgportType);
        }
        messagerUpdateLowMessager("msgport", 0x2cd1867Fb8016f93710B6386f7f9F1D540A60812);
    }
}
