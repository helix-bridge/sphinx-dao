// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base} from "./common/Base.sol";
import {safeconsole} from "forge-std/safeconsole.sol";
import "@helix/contracts/helix-contract/contracts/tool/TransparentUpgradeableProxy.sol";

interface XTokenBase {
    struct MessagerService {
        address sendService;
        address receiveService;
    }
    function transferOwnership(address newOwner) external;
    function setSendService(uint256 remoteChainId, address remoteBridge, address service) external;
    function setReceiveService(uint256 remoteChainId, address remoteBridge, address service) external;
    function messagers(uint256) external returns(MessagerService memory);
    function dao() external view returns (address);
    function pendingDao() external view returns (address);
}

interface IMsgportMessager {
    function dao() external view returns (address);
    function pendingDao() external view returns (address);
    function acceptOwnership() external;
}

interface IProxyAdmin {
    function getProxyAdmin(TransparentUpgradeableProxy proxy) external view returns (address);
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) external;
}

contract TransferXTokenOwnership9 is Base {
    address backingAddress = 0x2B496f19A420C02490dB859fefeCCD71eDc2c046;
    address issuingAddress = 0xDc0C760c0fB4672D06088515F6446a71Df0c64C1;
    address oldAdminOnDarwinia = 0x601dE3B81c7cE04BecE3b29e5cEe4F3251d250dB;
    address oldAdminOnEthereum = 0x601dE3B81c7cE04BecE3b29e5cEe4F3251d250dB;
    address newAdminOnDarwinia = 0xCfff66D03Ad2634d224b76967051Fa7B33fd0665;
    address newAdminOnEthereum = 0x44fE8409043F10c63B2b5B484774b1Cef122Cc32;
    address oldMessagerOnDarwinia = 0x65Be094765731F394bc6d9DF53bDF3376F1Fc8B0;
    address oldMessagerOnEthereum = 0x65Be094765731F394bc6d9DF53bDF3376F1Fc8B0;
    address newMessagerOnDarwinia = 0x682294D1c00A9CA13290b53B7544b8F734D6501f;
    address newMessagerOnEthereum = 0x02e5C0a36Fb0C83CCEBCD4D6177A7E223D6f0b7c;

    address newDao = 0x000000000879926D12aF396788C0785B7e581e53;

    uint256 ETHEREUM_CHAINID = 1;
    uint256 DARWINIA_CHAINID = 46;

    function run() public sphinx {
        if (block.chainid == DARWINIA_CHAINID) {
            /*
            XTokenBase backing = XTokenBase(backingAddress);
            require(backing.messagers(ETHEREUM_CHAINID).sendService == oldMessagerOnDarwinia, "!oldMessager");
            require(backing.messagers(ETHEREUM_CHAINID).receiveService == oldMessagerOnDarwinia, "!oldMessager");
            backing.setSendService(ETHEREUM_CHAINID, issuingAddress, newMessagerOnDarwinia);
            backing.setReceiveService(ETHEREUM_CHAINID, issuingAddress, newMessagerOnDarwinia);
            require(backing.messagers(ETHEREUM_CHAINID).sendService == newMessagerOnDarwinia, "!newMessager");
            require(backing.messagers(ETHEREUM_CHAINID).receiveService == newMessagerOnDarwinia, "!newMessager");

            if (IMsgportMessager(newMessagerOnDarwinia).pendingDao() == newDao) {
                IMsgportMessager(newMessagerOnDarwinia).acceptOwnership();
            }
            */

            // update proxyAdmin
            TransparentUpgradeableProxy backing = TransparentUpgradeableProxy(payable(backingAddress));
            require(IProxyAdmin(oldAdminOnDarwinia).getProxyAdmin(backing) == oldAdminOnDarwinia, "!oldAmin");
            IProxyAdmin(oldAdminOnDarwinia).changeProxyAdmin(backing, newAdminOnDarwinia);
            require(IProxyAdmin(newAdminOnDarwinia).getProxyAdmin(backing) == newAdminOnDarwinia, "!newAmin");
        } else if (block.chainid == ETHEREUM_CHAINID) {
            /*
            XTokenBase issuing = XTokenBase(issuingAddress);
            require(issuing.messagers(DARWINIA_CHAINID).sendService == oldMessagerOnEthereum, "!oldMessager");
            require(issuing.messagers(DARWINIA_CHAINID).receiveService == oldMessagerOnEthereum, "!oldMessager");
            issuing.setSendService(DARWINIA_CHAINID, backingAddress, newMessagerOnEthereum);
            issuing.setReceiveService(DARWINIA_CHAINID, backingAddress, newMessagerOnEthereum);
            require(issuing.messagers(DARWINIA_CHAINID).sendService == newMessagerOnEthereum, "!newMessager");
            require(issuing.messagers(DARWINIA_CHAINID).receiveService == newMessagerOnEthereum, "!newMessager");

            if (IMsgportMessager(newMessagerOnEthereum).pendingDao() == newDao) {
                IMsgportMessager(newMessagerOnEthereum).acceptOwnership();
            }
            */

            TransparentUpgradeableProxy issuing = TransparentUpgradeableProxy(payable(issuingAddress));
            require(IProxyAdmin(oldAdminOnEthereum).getProxyAdmin(issuing) == oldAdminOnEthereum, "!oldAmin");
            IProxyAdmin(oldAdminOnEthereum).changeProxyAdmin(issuing, newAdminOnEthereum);
            require(IProxyAdmin(newAdminOnEthereum).getProxyAdmin(issuing) == newAdminOnEthereum, "!newAmin");
        }
    }
}
