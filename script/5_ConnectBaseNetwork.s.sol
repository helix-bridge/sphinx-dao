// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract ConnectBaseNetwork is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();
        uint256 localChainId = block.chainid;
        if (localChainId == CHAINID_BASE) {
            for (uint idx = 0; idx < allChainIds.length; idx++) {
                uint256 remoteChainId = allChainIds[idx];
                if (remoteChainId == CHAINID_ETHEREUM) {
                    continue;
                }
                connectMessager(remoteChainId, MessagerType.LayerzeroType);
                connectBridge(remoteChainId, MessagerType.LayerzeroType);
            }
        } else {
            connectMessager(CHAINID_BASE, MessagerType.LayerzeroType);
            connectBridge(CHAINID_BASE, MessagerType.LayerzeroType);
        }
    }
}
