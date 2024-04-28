// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base} from "./common/Base.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

interface III {
    function dao() external view returns (address);
    function pendingDao() external view returns (address);
    function acceptOwnership() external;
}

contract AcceptOwnership3 is Base {
    uint256 OptimisticChainId = 10;
    uint256 ArbitrumChainId = 42161;
    uint256 LineaChainId = 59144;
    uint256 PolygonChainId = 137;
    uint256 BlastChainId = 81457;
    uint256 EthereumChainId = 1;

    function acceptAndCheckOwnership(address addr) internal {
        address dao = safeAddress();
        if (addr != address(0)) {
            if (dao == III(addr).pendingDao()) {
                III(addr).acceptOwnership();
            }
            require(III(addr).dao() == dao, "failed");
        }
    }

    function run() public sphinx {
        address lzMessager = address(0);
        address msgPortMessager = address(0);
        address lnv2Opposite = address(0);
        address lnv2Default = address(0);

        address lnv3 = address(0);
        if (block.chainid == ArbitrumChainId) {
            msgPortMessager = 0x65Be094765731F394bc6d9DF53bDF3376F1Fc8B0;
        } else if (block.chainid == LineaChainId) {
            lnv3 = 0xbA5D580B18b6436411562981e02c8A9aA1776D10;
        } else if (block.chainid == BlastChainId) {
            lzMessager = 0x98982b1685a63596834a05C1288dA7fbF27d684E;
            lnv3 = 0xB180D7DcB5CC161C862aD60442FA37527546cAFC;
        } else if (block.chainid == EthereumChainId) {
            msgPortMessager = 0x65Be094765731F394bc6d9DF53bDF3376F1Fc8B0;
            lnv3 = 0xbA5D580B18b6436411562981e02c8A9aA1776D10;
        }
        acceptAndCheckOwnership(lzMessager);
        acceptAndCheckOwnership(msgPortMessager);
        acceptAndCheckOwnership(lnv2Opposite);
        acceptAndCheckOwnership(lnv2Default);
        acceptAndCheckOwnership(lnv3);
    }
}
