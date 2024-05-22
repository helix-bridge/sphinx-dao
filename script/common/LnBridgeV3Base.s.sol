// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base} from "./Base.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {console} from "forge-std/console.sol";
import "./LnBridgeV3.sol";

interface Create2Deploy {
    function deploy(bytes memory code, uint256 salt) external;
}

interface ILnv3Bridge {
    struct MessagerService {
        address sendService;
        address receiveService;
    }
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
    function messagers(uint256 remoteChainId) view external returns(MessagerService memory);
    function setSendService(uint256 remoteChainId, address remoteBridge, address service) external;
    function setReceiveService(uint256 remoteChainId, address remoteBridge, address service) external;
    function getTokenKey(uint256 remoteChainId, address sourceToken, address targetToken) pure external returns(bytes32);
    function tokenInfos(bytes32 key) view external returns(TokenInfo memory);
    function tokenIndexer(uint32 index) view external returns(bytes32);
    function registerTokenInfo(
        uint256 remoteChainId,
        address sourceToken,
        address targetToken,
        uint112 protocolFee,
        uint112 penalty,
        uint8 sourceDecimals,
        uint8 targetDecimals,
        uint32 index
    ) external;
    function dao() view external returns(address);
    function pendingDao() view external returns(address);
    function acceptOwnership() external;
}

interface IErc20 {
    function decimals() view external returns(uint8);
    function symbol() view external returns(string memory);
}

interface IMessager {
    function acceptOwnership() external;
}

interface IMsgportMessager {
    struct RemoteMessager {
        uint256 msgportRemoteChainId;
        address messager;
    }
    function remoteMessagers(uint256 remoteChainId) view external returns(RemoteMessager memory);
    function setRemoteMessager(uint256 appRemoteChainId, uint256 msgportRemoteChainId, address remoteMessager) external;
}

interface ILayerZeroMessager {
    struct RemoteMessager {
        uint16 lzRemoteChainId;
        address messager;
    }
    function remoteMessagers(uint256 remoteChainId) view external returns(RemoteMessager memory);
    function setRemoteMessager(uint256 appRemoteChainId, uint16 lzRemoteChainId, address remoteMessager) external;
}

contract LnBridgeV3Base is Base {
    using stdToml for string;

    // helix-lnbridge-v3.0.0
    uint256 constant salt = 0x68656c69782d6c6e6272696467652d76332e302e30;
    string[] public allChainNames;

    enum MessagerType {
        LayerzeroType,
        MsgportType,
        Eth2ArbType
    }

    struct TokenInfo {
        address token;
        uint8 decimals;
        string symbol;
        bool configured;
    }

    struct BridgeInfo {
        string chainName;
        uint256 chainId;
        address deployer;
        address bridger;
    }

    struct MessagerInfo {
        address messager;
        uint256 chainId;
    }

    mapping(uint256=>BridgeInfo) public bridgerInfos;
    mapping(string=>uint256) public chainName2chainId;
    mapping(string=>MessagerType) public messagerName2messagerType;

    mapping(bytes32=>MessagerInfo) private messagers;
    mapping(bytes32=>TokenInfo) private tokens;

    function create2deploy(uint256 _salt, bytes memory initCode) internal {
        BridgeInfo memory bridgeInfo = bridgerInfos[block.chainid];
        address deployer = bridgeInfo.deployer;
        require(deployer != address(0), "deployer not exist");
        Create2Deploy(deployer).deploy(initCode, _salt);
    }

    function create2address(uint256 _salt, bytes32 bytecodeHash) internal view returns (address addr) {
        BridgeInfo memory bridgeInfo = bridgerInfos[block.chainid];
        address deployer = bridgeInfo.deployer;
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), _salt)
            mstore(ptr, deployer)
            let start := add(ptr, 0x0b)
            mstore8(start, 0xff)
            addr := and(keccak256(start, 85), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function initLnBridgeAddress() public {
        messagerName2messagerType['layerzero'] = MessagerType.LayerzeroType;
        messagerName2messagerType['msgport'] = MessagerType.MsgportType;
        messagerName2messagerType['eth2arb'] = MessagerType.Eth2ArbType;

        string[15] memory chains = ["arbitrum", "astar-zkevm", "base", "blast", "bsc", "ethereum", "gnosis", "linea", "mantle", "optimistic", "polygon-pos", "polygon-zkevm", "scroll", "darwinia", "moonbeam"];
        for (uint i = 0; i < chains.length; i++) {
            readConfig(chains[i]);
        }
    }

    function readConfig(string memory chainName) public {
        allChainNames.push(chainName);
        string memory root = vm.projectRoot();
        string memory config = vm.readFile(string.concat(root, "/script/config/", chainName, ".toml"));
        uint256 chainId = config.readUint(".base.chainId");
        chainName2chainId[chainName] = chainId;
        address deployer = config.readAddress(".base.deployer");
        address bridger = config.readAddress(".base.bridgev3");
        bridgerInfos[chainId] = BridgeInfo(chainName, chainId, deployer, bridger);

        string[] memory messagerNames = config.readStringArray(".messager.messagers.types");
        for (uint i = 0; i < messagerNames.length; i++) {
            string memory messagerName = messagerNames[i];
            MessagerType messagerType = messagerName2messagerType[messagerName];
            string memory channelIdKey = string.concat(".messager.", messagerName, ".id");
            string memory channelAddressKey = string.concat(".messager.", messagerName, ".messager");
            uint256 msgChainId = config.readUint(channelIdKey);
            address messager = config.readAddress(channelAddressKey);
            configureMessager(chainId, msgChainId, messagerType, messager);
        }
        string[] memory tokenSymbols = config.readStringArray(".token.symbols.symbols");
        for (uint i = 0; i < tokenSymbols.length; i++) {
            string memory symbol = tokenSymbols[i];
            string memory tokenAddressKey = string.concat(".token.", symbol, ".address");
            string memory tokenDecimalsKey = string.concat(".token.", symbol, ".decimals");
            address tokenAddress = config.readAddress(tokenAddressKey);
            uint8 tokenDecimals = uint8(config.readUint(tokenDecimalsKey));
            configureTokenInfo(chainId, symbol, tokenAddress, tokenDecimals);
        }
    }

    function configureMessager(uint256 chainId, uint256 lzChainId, MessagerType messagerType, address messagerAddress) internal {
        bytes32 key = keccak256(abi.encodePacked(chainId, messagerType));
        messagers[key] = MessagerInfo(messagerAddress, lzChainId);
    }

    function configureTokenInfo(uint256 chainId, string memory symbol, address token, uint8 decimals) internal {
        bytes32 key = keccak256(abi.encodePacked(chainId, symbol));
        tokens[key] = TokenInfo(token, decimals, symbol, true);
    }

    function getMessagerFromConfigure(uint256 chainId, MessagerType messagerType) public view returns(MessagerInfo memory messager) {
        bytes32 key = keccak256(abi.encodePacked(chainId, messagerType));
        messager = messagers[key];
    }

    function getTokenFromConfigure(uint256 chainId, string memory symbol) public view returns(TokenInfo memory) {
        bytes32 key = keccak256(abi.encodePacked(chainId, symbol));
        return tokens[key];
    }

    function getMessager(uint256 fromChain, uint256 toChain) public view returns(address sender, address receiver) {
        BridgeInfo memory bridgeInfo = bridgerInfos[fromChain];
        require(bridgeInfo.bridger != address(0), "the chain has no lnv3bridge");
        ILnv3Bridge.MessagerService memory service = ILnv3Bridge(bridgeInfo.bridger).messagers(toChain);
        sender = service.sendService;
        receiver = service.receiveService;
    }

    function checkTokenAddressOnChain(string memory symbol) public view {
        TokenInfo memory tokenInfo = getTokenFromConfigure(block.chainid, symbol);
        // ignore unconfigured token
        if (!tokenInfo.configured) {
            return;
        }
        require(IErc20(tokenInfo.token).decimals() == tokenInfo.decimals, "decimals not match");
    }

    // the proposol method
    // connect messager to remote chain
    function connectMessager(string memory remoteName, string memory messagerName) public {
        uint256 remoteChainId = chainName2chainId[remoteName];
        uint256 localChainId = block.chainid;
        MessagerType messagerType = messagerName2messagerType[messagerName];

        MessagerInfo memory localMessager = getMessagerFromConfigure(localChainId, messagerType);
        require(localMessager.messager != address(0), "local messager not exist");
        MessagerInfo memory remoteMessager = getMessagerFromConfigure(remoteChainId, messagerType);
        require(remoteMessager.messager != address(0), "remote messager not exist");

        if (messagerType == MessagerType.LayerzeroType) {
            uint16 lzRemoteChainId = uint16(remoteMessager.chainId);
            require(lzRemoteChainId != 0, "invalid lzchainid");
            ILayerZeroMessager.RemoteMessager memory oldMessager = ILayerZeroMessager(localMessager.messager).remoteMessagers(remoteChainId);
            // if the same configure, don't send tx
            if (oldMessager.lzRemoteChainId == lzRemoteChainId && oldMessager.messager == remoteMessager.messager) {
                return;
            }
            ILayerZeroMessager(localMessager.messager).setRemoteMessager(remoteChainId, lzRemoteChainId, remoteMessager.messager);
        } else if(messagerType == MessagerType.MsgportType) {
            IMsgportMessager.RemoteMessager memory oldMessager = IMsgportMessager(localMessager.messager).remoteMessagers(remoteChainId);
            // if the same configure, don't send tx
            if (oldMessager.messager == remoteMessager.messager) {
                return;
            }
            IMsgportMessager(localMessager.messager).setRemoteMessager(remoteChainId, remoteChainId, remoteMessager.messager);
        }
    }

    // connect lnbridge
    function connectBridge(string memory remoteName, string memory messagerName) public {
        uint256 remoteChainId = chainName2chainId[remoteName];
        MessagerType messagerType = messagerName2messagerType[messagerName];
        uint256 localChainId = block.chainid;
        BridgeInfo memory localBridge = bridgerInfos[localChainId];
        require(localBridge.bridger != address(0), "invalid local bridge");
        BridgeInfo memory remoteBridge = bridgerInfos[remoteChainId];
        require(remoteBridge.bridger != address(0), "invalid remote bridge");

        MessagerInfo memory localMessager = getMessagerFromConfigure(localChainId, messagerType);
        require(localMessager.messager != address(0), "local message not exist");

        (address sender, address receiver) = getMessager(localChainId, remoteChainId);
        if (sender != localMessager.messager) {
            ILnv3Bridge(localBridge.bridger).setSendService(remoteChainId, remoteBridge.bridger, localMessager.messager);
        }
        if (receiver != localMessager.messager) {
            ILnv3Bridge(localBridge.bridger).setReceiveService(remoteChainId, remoteBridge.bridger, localMessager.messager);
        }
    }

    // register token
    function registerToken(
        uint256 remoteChainId,
        string memory localSymbol,
        string memory remoteSymbol,
        uint112 protocolFee,
        uint112 penalty
    ) public {
        uint256 localChainId = block.chainid;
        TokenInfo memory localInfo = getTokenFromConfigure(localChainId, localSymbol);
        require(localInfo.configured, "local token not exist");
        TokenInfo memory remoteInfo = getTokenFromConfigure(remoteChainId, remoteSymbol);
        require(remoteInfo.configured, "remote token not exist");

        BridgeInfo memory localBridge = bridgerInfos[localChainId];
        require(localBridge.bridger != address(0), "invalid local bridge");
        bytes32 key = ILnv3Bridge(localBridge.bridger).getTokenKey(remoteChainId, localInfo.token, remoteInfo.token);
        ILnv3Bridge.TokenInfo memory tokenInfo = ILnv3Bridge(localBridge.bridger).tokenInfos(key);
        // has been registered
        if (tokenInfo.index > 0) {
            return;
        }
        uint32 index = 1;
        while (ILnv3Bridge(localBridge.bridger).tokenIndexer(index) != bytes32(0)) {
            index += 1;
        }
        ILnv3Bridge(localBridge.bridger).registerTokenInfo(
            remoteChainId,
            localInfo.token,
            remoteInfo.token,
            protocolFee,
            penalty,
            localInfo.decimals,
            remoteInfo.decimals,
            index
        );
    }

    function acceptOwnership() public {
        address dao = safeAddress();
        uint256 localChainId = block.chainid;
        BridgeInfo memory localBridge = bridgerInfos[localChainId];
        if (dao == ILnv3Bridge(localBridge.bridger).pendingDao()) {
            ILnv3Bridge(localBridge.bridger).acceptOwnership();
        }
        require(ILnv3Bridge(localBridge.bridger).dao() == dao, "failed");
    }

    function messagerAcceptOwnership(MessagerType messagerType) public {
        MessagerInfo memory messager = getMessagerFromConfigure(block.chainid, messagerType);
        require(messager.messager != address(0), "messager not exist");
        address dao = safeAddress();
        if (dao != ILnv3Bridge(messager.messager).dao() && dao == ILnv3Bridge(messager.messager).pendingDao()) {
            IMessager(messager.messager).acceptOwnership();
        }
        require(ILnv3Bridge(messager.messager).dao() == dao, "failed");
    }

    // deploy proxy admin
    function deployProxyAdmin() public returns(address) {
        bytes memory byteCode = type(HelixProxyAdmin).creationCode;
        address dao = safeAddress();
        bytes memory initCode = bytes.concat(byteCode, abi.encode(dao));
        address expectedAddress = create2address(salt, keccak256(initCode));
        if (expectedAddress.code.length == 0) {
            create2deploy(salt, initCode);
        }
        require(expectedAddress.code.length > 0, "proxy admin deployed failed");
        return expectedAddress;
    }

    // deploy msgport messager
    function deployMsgportMessager(address msgport) public returns(address) {
        bytes memory byteCode = type(MsgportMessager).creationCode;
        address dao = safeAddress();
        bytes memory initCode = bytes.concat(byteCode, abi.encode(dao, msgport));
        address expectedAddress = create2address(salt, keccak256(initCode));
        if (expectedAddress.code.length == 0) {
            create2deploy(salt, initCode);
        }
        require(expectedAddress.code.length > 0, "msgport messager deployed failed");
        return expectedAddress;
    }

    // deploy layerzero messager
    function deployLayerzeroMessager(address endpoint) public returns(address) {
        bytes memory byteCode = type(LayerZeroMessager).creationCode;
        address dao = safeAddress();
        bytes memory initCode = bytes.concat(byteCode, abi.encode(dao, endpoint));
        address expectedAddress = create2address(salt, keccak256(initCode));
        if (expectedAddress.code.length == 0) {
            create2deploy(salt, initCode);
        }
        require(expectedAddress.code.length > 0, "layerzero messager deployed failed");
        return expectedAddress;
    }

    // deploy lnv3 logic
    function deployLnBridgeV3Logic() public returns(address) {
        bytes memory byteCode = type(HelixLnBridgeV3).creationCode;
        address expectedAddress = create2address(salt, keccak256(byteCode));
        if (expectedAddress.code.length == 0) {
            create2deploy(salt, byteCode);
        }
        require(expectedAddress.code.length > 0, "lnbridgev3 deployed failed");
        return expectedAddress;
    }

    // deploy lnv3 proxy
    function deployLnBridgeV3Proxy(address logicAddress, address proxyAdminAddress) public returns(address) {
        bytes memory byteCode = type(TransparentUpgradeableProxy).creationCode;
        address dao = safeAddress();
        bytes memory data = abi.encodeWithSelector(
            HelixLnBridgeV3.initialize.selector,
            dao,
            bytes("0x")
        );
        bytes memory initCode = bytes.concat(byteCode, abi.encode(logicAddress, proxyAdminAddress, data));
        address expectedAddress = create2address(salt, keccak256(initCode));
        if (expectedAddress.code.length == 0) {
            create2deploy(salt, initCode);
        }
        require(expectedAddress.code.length > 0, "lnbridgev3 proxy deployed failed");
        return expectedAddress;
    }
}

