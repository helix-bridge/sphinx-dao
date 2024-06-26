// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract ConnectNetwork6 is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();

        uint256 CHAINID_ETHEREUM = chainName2chainId["ethereum"];
        uint256 CHAINID_DARWINIA = chainName2chainId["darwinia"];
        
        // accept ownership first
        if (block.chainid != CHAINID_ETHEREUM && block.chainid != CHAINID_DARWINIA) {
            acceptOwnership();
            messagerAcceptOwnership(MessagerType.LayerzeroType);
            for (uint idx = 0; idx < allChainNames.length; idx++) {
                string memory remoteChainName = allChainNames[idx];
                uint256 remoteChainId = chainName2chainId[remoteChainName];
                if (remoteChainId == CHAINID_ETHEREUM || remoteChainId == block.chainid || remoteChainId == CHAINID_DARWINIA) {
                    continue;
                }
                connectMessager(remoteChainName, "layerzero");
                connectBridge(remoteChainName, "layerzero");
            }
        }
    }
}
