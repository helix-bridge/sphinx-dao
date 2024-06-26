// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LnBridgeV3Base} from "./common/LnBridgeV3Base.s.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

interface ILnBridge {
    function protocolFeeReceiver() view external returns(address);
    function updateFeeReceiver(address receiver) external;
}

contract MoveProtocolFeeReceiver10 is LnBridgeV3Base {
    function run() public sphinx {
        initLnBridgeAddress();

        uint256 ARBITRUM = chainName2chainId["arbitrum"];
        uint256 OP = chainName2chainId["optimistic"];
        uint256 LINEA = chainName2chainId["linea"];
        uint256 POLYGON_POS = chainName2chainId["polygon-pos"];
        uint256 ETHEREUM = chainName2chainId["ethereum"];
        uint256 DARWINIA = chainName2chainId["darwinia"];
        uint256 BSC = chainName2chainId["bsc"];
        uint256 BASE = chainName2chainId["base"];
        uint256 GNOSIS = chainName2chainId["gnosis"];
        uint256 MANTLE = chainName2chainId["mantle"];
        uint256 SCROLL = chainName2chainId["scroll"];

        address dao = safeAddress();

        {
            address lnv2DefaultAddress = 0x94C614DAeFDbf151E1BB53d6A201ae5fF56A9337;
            uint256[11] memory defaultChains = [
                ARBITRUM,
                OP,
                LINEA,
                POLYGON_POS,
                ETHEREUM,
                DARWINIA,
                BSC,
                BASE,
                GNOSIS,
                MANTLE,
                SCROLL
            ];
            for (uint i = 0; i < defaultChains.length; i++) {
                if (block.chainid == defaultChains[i] && ILnBridge(lnv2DefaultAddress).protocolFeeReceiver() != dao) {
                    ILnBridge(lnv2DefaultAddress).updateFeeReceiver(dao);
                    break;
                }
            }
        }
        {
            address lnv2OppositeAddress = 0x48d769d5C7ff75703cDd1543A1a2ed9bC9044A23;
            uint256[3] memory oppositeChains = [
                ARBITRUM,
                ETHEREUM,
                DARWINIA
            ];
            for (uint i = 0; i < oppositeChains.length; i++) {
                if (block.chainid == oppositeChains[i] && ILnBridge(lnv2OppositeAddress).protocolFeeReceiver() != dao) {
                    ILnBridge(lnv2OppositeAddress).updateFeeReceiver(dao);
                    break;
                }
            }
        }
    }
}
