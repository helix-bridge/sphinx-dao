// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract ConnectBaseNetwork is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();
        uint256 localChainId = block.chainid;
        uint256 CHAINID_BASE = chainName2chainId["base"];
        uint256 CHAINID_ETHEREUM = chainName2chainId["ethereum"];
        if (localChainId == CHAINID_BASE) {
            for (uint idx = 0; idx < allChainNames.length; idx++) {
                string memory remoteChainName = allChainNames[idx];
                uint256 remoteChainId = chainName2chainId[remoteChainName];
                if (remoteChainId == CHAINID_ETHEREUM) {
                    continue;
                }
                connectMessager(remoteChainName, "layerzero");
                connectBridge(remoteChainName, "layerzero");
            }
        } else {
            connectMessager("base", "layerzero");
            connectBridge("base", "layerzero");
        }
    }
}
