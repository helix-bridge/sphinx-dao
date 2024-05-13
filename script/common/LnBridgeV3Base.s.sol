// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base} from "./Base.sol";
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
}

interface IErc20 {
    function decimals() view external returns(uint8);
    function symbol() view external returns(string memory);
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
    uint256 constant CHAINID_ETHEREUM = 1;
    uint256 constant CHAINID_ARBITRUM = 42161;
    uint256 constant CHAINID_POLYGON_POS = 137;
    uint256 constant CHAINID_BSC = 56;
    uint256 constant CHAINID_LINEA = 59144;
    uint256 constant CHAINID_BASE = 8453;
    uint256 constant CHAINID_OP = 10;
    uint256 constant CHAINID_GNOSIS = 100;
    uint256 constant CHAINID_MANTLE = 5000;
    uint256 constant CHAINID_SCROLL = 534352;
    uint256 constant CHAINID_DARWINIA = 46;
    uint256 constant CHAINID_POLYGON_ZKEVM = 1101;
    uint256 constant CHAINID_BLAST = 81457;
    uint256 constant CHAINID_ASTAR_ZKEVM = 3776;
    // helix-lnbridge-v3.0.0
    uint256 constant salt = 0x68656c69782d6c6e6272696467652d76332e302e30;
    uint256[] public allChainIds;

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

    // the address on each chain
    mapping(uint256=>address) public lnBridgeAddresses;
    mapping(uint256=>uint16) public lzChainIds;
    mapping(uint256=>address) public deployers;
    mapping(bytes32=>address) private messagers;
    mapping(bytes32=>TokenInfo) private tokens;

    function create2deployAddress() internal view returns(address) {
        return address(0);
    }

    function create2deploy(uint256 _salt, bytes memory initCode) internal {
        address deployer = create2deployAddress();
        require(deployer != address(0), "deployer not exist");
        Create2Deploy(deployer).deploy(initCode, _salt);
    }

    function create2address(uint256 _salt, bytes32 bytecodeHash) internal view returns (address addr) {
        address deployer = create2deployAddress();
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
        address commonAddress = 0xbA5D580B18b6436411562981e02c8A9aA1776D10;
        allChainIds.push(CHAINID_ETHEREUM);
        allChainIds.push(CHAINID_ARBITRUM);
        allChainIds.push(CHAINID_POLYGON_POS);
        allChainIds.push(CHAINID_BSC);
        allChainIds.push(CHAINID_LINEA);
        allChainIds.push(CHAINID_BASE);
        allChainIds.push(CHAINID_OP);
        allChainIds.push(CHAINID_GNOSIS);
        allChainIds.push(CHAINID_MANTLE);
        allChainIds.push(CHAINID_SCROLL);
        allChainIds.push(CHAINID_POLYGON_ZKEVM);
        allChainIds.push(CHAINID_BLAST);
        allChainIds.push(CHAINID_ASTAR_ZKEVM);

        lnBridgeAddresses[CHAINID_ETHEREUM] = commonAddress;
        lnBridgeAddresses[CHAINID_ARBITRUM] = commonAddress;
        lnBridgeAddresses[CHAINID_POLYGON_POS] = commonAddress;
        lnBridgeAddresses[CHAINID_BSC] = commonAddress;
        lnBridgeAddresses[CHAINID_LINEA] = commonAddress;
        lnBridgeAddresses[CHAINID_BASE] = commonAddress;
        lnBridgeAddresses[CHAINID_OP] = commonAddress;
        lnBridgeAddresses[CHAINID_GNOSIS] = commonAddress;
        lnBridgeAddresses[CHAINID_MANTLE] = commonAddress;
        lnBridgeAddresses[CHAINID_SCROLL] = commonAddress;
        lnBridgeAddresses[CHAINID_POLYGON_ZKEVM] = commonAddress;
        lnBridgeAddresses[CHAINID_BLAST] = 0xB180D7DcB5CC161C862aD60442FA37527546cAFC;
        lnBridgeAddresses[CHAINID_ASTAR_ZKEVM] = 0xD476650e03a45E70202b0bcAfa04E1513920f83a;

        address commonDeployer = 0x80D4c766C5142D1313D531Afe7384D0D5E108Db3;
        deployers[CHAINID_ETHEREUM] = commonDeployer;
        deployers[CHAINID_ARBITRUM] = commonDeployer;
        deployers[CHAINID_POLYGON_POS] = commonDeployer;
        deployers[CHAINID_BSC] = commonDeployer;
        deployers[CHAINID_LINEA] = commonDeployer;
        deployers[CHAINID_BASE] = commonDeployer;
        deployers[CHAINID_OP] = commonDeployer;
        deployers[CHAINID_GNOSIS] = commonDeployer;
        deployers[CHAINID_MANTLE] = commonDeployer;
        deployers[CHAINID_SCROLL] = commonDeployer;
        deployers[CHAINID_POLYGON_ZKEVM] = commonDeployer;
        deployers[CHAINID_BLAST] = 0x9bc1C7567DDBcaF2212185b6665D755d842d01E4;
        deployers[CHAINID_ASTAR_ZKEVM] = 0x9bc1C7567DDBcaF2212185b6665D755d842d01E4;

        lzChainIds[CHAINID_ETHEREUM] = 101;
        lzChainIds[CHAINID_ARBITRUM] = 110;
        lzChainIds[CHAINID_POLYGON_POS] = 109;
        lzChainIds[CHAINID_BSC] = 102;
        lzChainIds[CHAINID_LINEA] = 183;
        lzChainIds[CHAINID_BASE] = 184;
        lzChainIds[CHAINID_OP] = 111;
        lzChainIds[CHAINID_GNOSIS] = 145;
        lzChainIds[CHAINID_MANTLE] = 181;
        lzChainIds[CHAINID_SCROLL] = 214;
        lzChainIds[CHAINID_POLYGON_ZKEVM] = 158;
        lzChainIds[CHAINID_BLAST] = 243;
        lzChainIds[CHAINID_ASTAR_ZKEVM] = 257;

        configureMessager(CHAINID_ETHEREUM, MessagerType.MsgportType, 0x65Be094765731F394bc6d9DF53bDF3376F1Fc8B0);
        configureMessager(CHAINID_ETHEREUM, MessagerType.Eth2ArbType, 0x78a6831Da2293fbEFd0d8aFB4D1f7CBB751e0119);
        configureMessager(CHAINID_ARBITRUM, MessagerType.LayerzeroType, 0x509354A4ebf98aCC7a65d2264694A65a2938cac9);
        configureMessager(CHAINID_ARBITRUM, MessagerType.MsgportType, 0x65Be094765731F394bc6d9DF53bDF3376F1Fc8B0);
        configureMessager(CHAINID_ARBITRUM, MessagerType.Eth2ArbType, 0xc95D939Da72ECe8Bd794d42EaEd28974CDb0ADa2);
        configureMessager(CHAINID_POLYGON_POS, MessagerType.LayerzeroType, 0x463D1730a8527CA58d48EF70C7460B9920346567);
        configureMessager(CHAINID_BSC, MessagerType.LayerzeroType, 0x61B6B8c7C00aA7F060a2BEDeE6b11927CC9c3eF1);
        configureMessager(CHAINID_LINEA, MessagerType.LayerzeroType, 0x61B6B8c7C00aA7F060a2BEDeE6b11927CC9c3eF1);
        configureMessager(CHAINID_BASE, MessagerType.LayerzeroType, 0x61B6B8c7C00aA7F060a2BEDeE6b11927CC9c3eF1);
        configureMessager(CHAINID_OP, MessagerType.LayerzeroType, 0x61B6B8c7C00aA7F060a2BEDeE6b11927CC9c3eF1);
        configureMessager(CHAINID_GNOSIS, MessagerType.LayerzeroType, 0x3F7DF5866591e7E48D18C8EbeAE61Bc343a63283);
        configureMessager(CHAINID_MANTLE, MessagerType.LayerzeroType, 0x61B6B8c7C00aA7F060a2BEDeE6b11927CC9c3eF1);
        configureMessager(CHAINID_SCROLL, MessagerType.LayerzeroType, 0x463D1730a8527CA58d48EF70C7460B9920346567);
        configureMessager(CHAINID_POLYGON_ZKEVM, MessagerType.LayerzeroType, 0x61B6B8c7C00aA7F060a2BEDeE6b11927CC9c3eF1);
        configureMessager(CHAINID_BLAST, MessagerType.LayerzeroType, 0x8A87497488073307E1a17e8A12475a94Afcb413f);
        configureMessager(CHAINID_BLAST, MessagerType.MsgportType, 0x98982b1685a63596834a05C1288dA7fbF27d684E);
        configureMessager(CHAINID_ASTAR_ZKEVM, MessagerType.LayerzeroType, 0x61B6B8c7C00aA7F060a2BEDeE6b11927CC9c3eF1);


        configureTokenInfo(CHAINID_ETHEREUM, "ring", 0x9469D013805bFfB7D3DEBe5E7839237e535ec483, 18);
        configureTokenInfo(CHAINID_ARBITRUM, "usdt", 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, 6);
        configureTokenInfo(CHAINID_ARBITRUM, "usdc", 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, 6);
        configureTokenInfo(CHAINID_ARBITRUM, "ring", 0x9e523234D36973f9e38642886197D023C88e307e, 18);
        configureTokenInfo(CHAINID_POLYGON_POS, "usdt", 0xc2132D05D31c914a87C6611C10748AEb04B58e8F, 6);
        configureTokenInfo(CHAINID_POLYGON_POS, "ring", 0x9C1C23E60B72Bc88a043bf64aFdb16A02540Ae8f, 18);
        configureTokenInfo(CHAINID_BSC, "usdt", 0x55d398326f99059fF775485246999027B3197955, 18);
        configureTokenInfo(CHAINID_BSC, "usdc", 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, 18);
        configureTokenInfo(CHAINID_LINEA, "usdt", 0xA219439258ca9da29E9Cc4cE5596924745e12B93, 6);
        configureTokenInfo(CHAINID_BASE, "usdc", 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, 6);
        configureTokenInfo(CHAINID_OP, "usdt", 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58, 6);
        configureTokenInfo(CHAINID_GNOSIS, "usdt", 0x4ECaBa5870353805a9F068101A40E0f32ed605C6, 6);
        configureTokenInfo(CHAINID_MANTLE, "usdt", 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE, 6);
        configureTokenInfo(CHAINID_MANTLE, "usdc", 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9, 6);
        configureTokenInfo(CHAINID_SCROLL, "usdt", 0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df, 6);
        configureTokenInfo(CHAINID_SCROLL, "usdc", 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4, 6);
        configureTokenInfo(CHAINID_POLYGON_ZKEVM, "usdt", 0x1E4a5963aBFD975d8c9021ce480b42188849D41d, 6);
        configureTokenInfo(CHAINID_BLAST, "usdb", 0x4300000000000000000000000000000000000003, 6);
        configureTokenInfo(CHAINID_ASTAR_ZKEVM, "usdt", 0x493257fD37EDB34451f62EDf8D2a0C418852bA4C, 6);
        configureTokenInfo(CHAINID_ASTAR_ZKEVM, "usdc", 0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4, 6);
    }

    function configureMessager(uint256 chainId, MessagerType messagerType, address messagerAddress) internal {
        bytes32 key = keccak256(abi.encodePacked(chainId, messagerType));
        messagers[key] = messagerAddress;
    }

    function configureTokenInfo(uint256 chainId, string memory symbol, address token, uint8 decimals) internal {
        bytes32 key = keccak256(abi.encodePacked(chainId, symbol));
        tokens[key] = TokenInfo(token, decimals, symbol, true);
    }

    function getMessagerFromConfigure(uint256 chainId, MessagerType messagerType) public view returns(address messager) {
        bytes32 key = keccak256(abi.encodePacked(chainId, messagerType));
        messager = messagers[key];
    }

    function getTokenFromConfigure(uint256 chainId, string memory symbol) public view returns(TokenInfo memory) {
        bytes32 key = keccak256(abi.encodePacked(chainId, symbol));
        return tokens[key];
    }

    function getMessager(uint256 fromChain, uint256 toChain) public view returns(address sender, address receiver) {
        address lnv3BridgeAddress = lnBridgeAddresses[fromChain];
        require(lnv3BridgeAddress != address(0), "the chain has no lnv3bridge");
        ILnv3Bridge.MessagerService memory service = ILnv3Bridge(lnv3BridgeAddress).messagers(toChain);
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
    function connectMessager(uint256 remoteChainId, MessagerType messagerType) public {
        uint256 localChainId = block.chainid;
        address localMessager = getMessagerFromConfigure(localChainId, messagerType);
        require(localMessager != address(0), "local messager not exist");
        address remoteMessager = getMessagerFromConfigure(remoteChainId, messagerType);
        require(remoteMessager != address(0), "remote messager not exist");

        if (messagerType == MessagerType.LayerzeroType) {
            uint16 lzRemoteChainId = lzChainIds[remoteChainId];
            require(lzRemoteChainId != 0, "invalid lzchainid");
            ILayerZeroMessager.RemoteMessager memory oldMessager = ILayerZeroMessager(localMessager).remoteMessagers(remoteChainId);
            // if the same configure, don't send tx
            if (oldMessager.lzRemoteChainId == lzRemoteChainId && oldMessager.messager == remoteMessager) {
                return;
            }
            ILayerZeroMessager(localMessager).setRemoteMessager(remoteChainId, lzRemoteChainId, remoteMessager);
        } else if(messagerType == MessagerType.MsgportType) {
            IMsgportMessager.RemoteMessager memory oldMessager = IMsgportMessager(localMessager).remoteMessagers(remoteChainId);
            // if the same configure, don't send tx
            if (oldMessager.messager == remoteMessager) {
                return;
            }
            IMsgportMessager(localMessager).setRemoteMessager(remoteChainId, remoteChainId, remoteMessager);
        }
    }

    // connect lnbridge
    function connectBridge(uint256 remoteChainId, MessagerType messagerType) public {
        uint256 localChainId = block.chainid;
        address localBridge = lnBridgeAddresses[localChainId];
        require(localBridge != address(0), "invalid local bridge");
        address remoteBridge = lnBridgeAddresses[remoteChainId];
        require(remoteBridge != address(0), "invalid remote bridge");

        address localMessager = getMessagerFromConfigure(localChainId, messagerType);
        require(localMessager != address(0), "local message not exist");

        (address sender, address receiver) = getMessager(localChainId, remoteChainId);
        if (sender != localMessager) {
            ILnv3Bridge(localBridge).setSendService(remoteChainId, remoteBridge, localMessager);
        }
        if (receiver != localMessager) {
            ILnv3Bridge(localBridge).setReceiveService(remoteChainId, remoteBridge, localMessager);
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

        address localBridge = lnBridgeAddresses[localChainId];
        require(localBridge != address(0), "invalid local bridge");
        bytes32 key = ILnv3Bridge(localBridge).getTokenKey(remoteChainId, localInfo.token, remoteInfo.token);
        ILnv3Bridge.TokenInfo memory tokenInfo = ILnv3Bridge(localBridge).tokenInfos(key);
        // has been registered
        if (tokenInfo.index > 0) {
            return;
        }
        uint32 index = 1;
        while (ILnv3Bridge(localBridge).tokenIndexer(index) != bytes32(0)) {
            index += 1;
        }
        ILnv3Bridge(localBridge).registerTokenInfo(
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

    // deploy proxy admin
    function deployProxyAdmin() external returns(address) {
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
    function deployMsgportMessager(address msgport) external returns(address) {
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
    function deployLayerzeroMessager(address endpoint) external returns(address) {
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
    function deployLnBridgeV3Logic() external returns(address) {
        bytes memory byteCode = type(HelixLnBridgeV3).creationCode;
        address expectedAddress = create2address(salt, keccak256(byteCode));
        if (expectedAddress.code.length == 0) {
            create2deploy(salt, byteCode);
        }
        require(expectedAddress.code.length > 0, "lnbridgev3 deployed failed");
        return expectedAddress;
    }

    // deploy lnv3 proxy
    function deployLnBridgeV3Proxy(address logicAddress, address proxyAdminAddress) external returns(address) {
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

