// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { HelloSphinx } from "../src/HelloSphinx.sol";
import "@sphinx-labs/contracts/SphinxPlugin.sol";

contract HelloSphinxScript is Sphinx, Script {
    HelloSphinx helloSphinx;

    function configureSphinx() public override {
        sphinxConfig.owners = [0xD70A2e6eACbdeDA77a5d4bBAE3bC70239A0e088f];
        sphinxConfig.orgId = "cluanacaw000111jik4xs4wkl";
        sphinxConfig.threshold = 1;
        sphinxConfig.projectName = "My_First_Project";
    }

    function run() public sphinx {
        // Set the `CREATE2` salt to be the hash of the owner(s). Prevents
        // address collisions.
        bytes32 salt = keccak256(abi.encode(sphinxConfig.owners));
        helloSphinx = new HelloSphinx{ salt: salt }("Hi", 2);
        helloSphinx.add(8);
    }
}
