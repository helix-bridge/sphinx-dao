// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

contract ConnectNetworkAndRegisterUsdt7 is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();

        uint256 CHAINID_ETHEREUM = chainName2chainId["ethereum"];
        uint256 CHAINID_DARWINIA = chainName2chainId["darwinia"];
        
        // connect networks
        if (block.chainid != CHAINID_ETHEREUM && block.chainid != CHAINID_DARWINIA) {
            acceptOwnership();
            messagerAcceptOwnership(MessagerType.LayerzeroType);
            TokenInfo memory localTokenInfo = getTokenFromConfigure(block.chainid, "usdt");
            for (uint idx = 0; idx < allChainNames.length; idx++) {
                string memory remoteChainName = allChainNames[idx];
                uint256 remoteChainId = chainName2chainId[remoteChainName];
                if (remoteChainId == CHAINID_ETHEREUM || remoteChainId == block.chainid || remoteChainId == CHAINID_DARWINIA) {
                    continue;
                }
                connectMessager(remoteChainName, "layerzero");
                connectBridge(remoteChainName, "layerzero");

                TokenInfo memory remoteTokenInfo = getTokenFromConfigure(remoteChainId, "usdt");
                if (localTokenInfo.token != address(0) && remoteTokenInfo.token != address(0)) {
                    // 2
                    uint256 penalty = 2 * 10 ** localTokenInfo.decimals;
                    registerToken(remoteChainId, localTokenInfo.symbol, remoteTokenInfo.symbol, localTokenInfo.protocolFee, uint112(penalty));
                }
            }
        }
    }
}
