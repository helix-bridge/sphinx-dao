// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "@sphinx-labs/contracts/SphinxPlugin.sol";

contract Base is Sphinx, Script {
    function configureSphinx() public override {
        sphinxConfig.projectName = "Helix-DAO";
        sphinxConfig.mainnets = ["darwinia", "arbitrum", "astar-zkevm", "optimistic", "linea", "ethereum", "blast", "darwinia", "bsc", "base", "gnosis", "mantle", "scroll" ];
    }
}
