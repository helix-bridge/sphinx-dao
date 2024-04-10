.PHONY: all fmt clean dry-run propose
.PHONY: tools foundry sync sphinx

-include .env

all    :; @forge build
fmt    :; @forge fmt
clean  :; @forge clean

propose:; npx sphinx propose ./script/common/Proposal.s.sol --networks mainnets
dry-run:; npx sphinx propose ./script/common/Proposal.s.sol --networks mainnets --dry-run

sphinx :; @yarn sphinx install
sync   :; @git submodule update --recursive
tools  :  foundry
foundry:; curl -L https://foundry.paradigm.xyz | bash
