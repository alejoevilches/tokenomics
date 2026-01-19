-include .env
deploy-sepolia:
	forge script script/DeployTokenomics.s.sol:DeployTokenomics --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvv;
verify-contract-sepolia:
	forge verify-contract --chain sepolia --etherscan-api-key $(ETHERSCAN_API_KEY) $(ADDRESS) src/RaffleFactory.sol:RaffleFactory;