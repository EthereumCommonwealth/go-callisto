package ethash

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

var (
	// CLOMinerReward - Block reward in wei for successfully mining a block upward for Callisto Network
	CLOMinerReward = new(big.Int).Mul(big.NewInt(420), big.NewInt(1e+18))
	// CLOTreasuryReward - Block reward in wei for successfully mining a block upward for Callisto Network
	CLOTreasuryReward = new(big.Int).Mul(big.NewInt(120), big.NewInt(1e+18))
	// CLOStakeReward - Block reward in wei for successfully mining a block upward for Callisto Network
	CLOStakeReward = new(big.Int).Mul(big.NewInt(60), big.NewInt(1e+18))
	// CLOHF1TreasuryReward - Block reward in wei for successfully mining a block upward for Callisto Network
	CLOHF1TreasuryReward = new(big.Int).Mul(big.NewInt(60), big.NewInt(1e+18))
	// CLOHF1StakeReward - Block reward in wei for successfully mining a block upward for Callisto Network
	CLOHF1StakeReward = new(big.Int).Mul(big.NewInt(120), big.NewInt(1e+18))
	// CLOReserveReward - Block reward in wei for successfully mining a block upward for Callisto Network
	CLOReserveReward = new(big.Int).Mul(big.NewInt(0), big.NewInt(1e+18))	
	// CLOTreasuryAddress - Treasury Address
	CLOTreasuryAddress = common.HexToAddress("0x74682Fc32007aF0b6118F259cBe7bCCC21641600")
	// CLOStakeAddress - Stake Address before HF1
	CLOStakeAddress = common.HexToAddress("0x3c06f218Ce6dD8E2c535a8925A2eDF81674984D9")
	// CLOHF1StakeAddress - Staking Address HF1
	CLOHF1StakeAddress = common.HexToAddress("0xd813419749b3c2cdc94a2f9cfcf154113264a9d6")
	// CSV2StakeAddress - Staking Address V2 (MAINNET)
	CSV2StakeAddress = common.HexToAddress("0x08A7c8be47773546DC5E173d67B0c38AfFfa4b84")
	// CSV2StakeAddressTestNet - Staking Address V2 (TESTNET)
	CSV2StakeAddressTestNet = common.HexToAddress("0xBD38997D00295D738BDC258DB4446577f4181Ed7")
	// CLOReserveAddress - Reserve Address
	CLOReserveAddress = common.HexToAddress("0x0000000000000000000000000000000000000000")
	
	// Settings from MonetaryPolicy contract
	DAOMPAddress = common.HexToAddress("0x3c0a04dDD9Bd580e152e29b1d702000e7460c299")
	DAOMPMinerRewardKey = common.HexToHash("0x0")
	DAOMPTreasuryRewardKey = common.HexToHash("0x1")
	DAOMPStakeRewardKey = common.HexToHash("0x2")
	DAOMPReserveRewardKey = common.HexToHash("0x3")
	DAOMPTreasuryAddressKey = common.HexToHash("0x4")
	DAOMPStakeAddressKey = common.HexToHash("0x5")
	DAOMPReserveAddressKey = common.HexToHash("0x6")
)

func calcBigNumber(reward float64) *big.Int {
	bigReward := new(big.Float).Mul(big.NewFloat(reward), big.NewFloat(1e+18))
	bigRewardInt := new(big.Int)
	bigReward.Int(bigRewardInt)
	return bigRewardInt
}

func getCLOMonetaryPolicyMinerReward(blockNumber *big.Int) *big.Int {
	switch {
	case big.NewInt(2900001).Cmp(blockNumber) == 0:
		return calcBigNumber(234)
	case big.NewInt(4400001).Cmp(blockNumber) == 0:
		return calcBigNumber(129.6)
	case big.NewInt(5900001).Cmp(blockNumber) == 0:
		return calcBigNumber(71.28)
	}
	return calcBigNumber(38.88)
}

func getCLOMonetaryPolicyTreasury(blockNumber *big.Int) *big.Int {
	switch {
	case big.NewInt(2900001).Cmp(blockNumber) == 0:
		return calcBigNumber(36)
	case big.NewInt(4400001).Cmp(blockNumber) == 0:
		return calcBigNumber(21.6)
	case big.NewInt(5900001).Cmp(blockNumber) == 0:
		return calcBigNumber(12.96)
	}
	return calcBigNumber(7.77)
}

func getCLOMonetaryPolicyStake(blockNumber *big.Int) *big.Int {
	switch {
	case big.NewInt(2900001).Cmp(blockNumber) == 0:
		return calcBigNumber(90)
	case big.NewInt(4400001).Cmp(blockNumber) == 0:
		return calcBigNumber(64.8)
	case big.NewInt(5900001).Cmp(blockNumber) == 0:
		return calcBigNumber(45.36)
	}
	return calcBigNumber(31.1)
}

func getMonetaryPolicyStepMainnet(blockNumber *big.Int) *big.Int {
	if blockNumber.Cmp(big.NewInt(4400001)) == -1 {
		return big.NewInt(2900001)
	} else if blockNumber.Cmp(big.NewInt(5900001)) == -1 {
		return big.NewInt(4400001)
	} else if blockNumber.Cmp(big.NewInt(7400001)) == -1 {
		return big.NewInt(5900001)
	}
	return big.NewInt(7400001)
}

func getMonetaryPolicyStepTestnet(blockNumber *big.Int) *big.Int {
	if blockNumber.Cmp(big.NewInt(2000)) == -1 {
		return big.NewInt(2900001)
	} else if blockNumber.Cmp(big.NewInt(3000)) == -1 {
		return big.NewInt(4400001)
	} else if blockNumber.Cmp(big.NewInt(4000)) == -1 {
		return big.NewInt(5900001)
	}
	return big.NewInt(7400001)
}
