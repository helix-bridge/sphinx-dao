// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "@sphinx-labs/contracts/SphinxPlugin.sol";

contract Base is Sphinx, Script {
    function configureSphinx() public override {
        sphinxConfig.owners = [
            0xD70A2e6eACbdeDA77a5d4bBAE3bC70239A0e088f, // CI
            0x00E3993566b34e5367d1C602439997BD08c11FF7, // Alex
            0x52386BE2397e8EAc26298F733b390684203fB580, // Denny
            0xe59261f6D4088BcD69985A3D369Ff14cC54EF1E5, // Ranji
            0x88a39B052d477CfdE47600a7C9950a441Ce61cb4 // Xiaoch
        ];
        sphinxConfig.orgId = "cluanacaw000111jik4xs4wkl";
        sphinxConfig.threshold = 3;
        sphinxConfig.projectName = "Helix-DAO";
        // sphinxConfig.mainnets = ["polygon", "arbitrum", "optimism", "mantle"];
        sphinxConfig.mainnets = ["polygon", "arbitrum", "optimism"];
    }
}
