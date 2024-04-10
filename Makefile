.PHONY: all fmt clean test
.PHONY: tools foundry sync

-include .env



all    :; @forge build
fmt    :; @forge fmt
clean  :; @forge clean

propose-deploy-test  :; @SPHINX_API_KEY=$(SPHINX_API_KEY) npx sphinx propose ./script/Deploy.s.sol  --networks testnets
propose-deploy-prod  :; @SPHINX_API_KEY=$(SPHINX_API_KEY) npx sphinx propose ./script/Deploy.s.sol  --networks mainnets

sphinx :; @yarn sphinx install
sync   :; @git submodule update --recursive
tools  :  foundry
foundry:; curl -L https://foundry.paradigm.xyz | bash
