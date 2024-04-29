// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base} from "./common/Base.sol";
import {safeconsole} from "forge-std/safeconsole.sol";

interface IHelixBridgeV3 {
    struct TokenConfigure {
        uint112 protocolFee;
        uint112 penalty;
        uint8 sourceDecimals;
        uint8 targetDecimals;
    }
    struct TokenInfo {
        TokenConfigure config;
        uint32 index;
        address sourceToken;
        address targetToken;
        uint256 protocolFeeIncome;
    }
    function updateTokenInfo(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _protocolFee,
        uint112 _penalty,
        uint8 _sourceDecimals,
        uint8 _targetDecimals
    ) external;
    function getTokenKey(uint256 _remoteChainId, address _sourceToken, address _targetToken) pure external returns(bytes32);
    function tokenInfos(bytes32 key) view external returns(TokenInfo memory);
    function tokenIndexer(uint32 index) view external returns(bytes32);
}

contract UpdateArbOpEthProtocolFee4 is Base {
    address HelixBridge = 0xbA5D580B18b6436411562981e02c8A9aA1776D10;
    uint256 OptimisticChainId = 10;
    uint256 ArbitrumChainId = 42161;

    function run() public sphinx {
        uint256 remoteChainId = (block.chainid == OptimisticChainId ? ArbitrumChainId : OptimisticChainId); // arbitrum
        address nativeAddress = address(0);
        uint112 protocolFee = 10000000000000;
        uint112 penalty = 1500000000000000;
        uint8 decimals = 18;
        uint32 index = block.chainid == OptimisticChainId ? 9 : 14;
        require(block.chainid == OptimisticChainId || block.chainid == ArbitrumChainId);
        require(block.chainid != remoteChainId, "invalid chainid");
        bytes32 tokenKey = IHelixBridgeV3(HelixBridge).getTokenKey(
            remoteChainId,
            nativeAddress,
            nativeAddress
        );
        require(IHelixBridgeV3(HelixBridge).tokenInfos(tokenKey).index == index, "index not matched");
        IHelixBridgeV3(HelixBridge).updateTokenInfo(
            remoteChainId,
            nativeAddress,
            nativeAddress,
            protocolFee,
            penalty,
            decimals,
            decimals
        );
    }
}
