// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tokenomics is ERC20 {
    struct StakePosition {
        uint256 amount;
        uint256 lockedUntil;
        uint256 userRewardIndex;
    }

    mapping(address => StakePosition) public stakedPerAccount;

    uint256 totalStaked;
    uint256 public constant INITIAL_SUPPLY = 100000 ether;
    uint256 public constant LOCK_PERIOD = 14 days;
    uint256 public constant PRECISION = 1e18;
    uint256 public volumePerTerm;
    uint256 public startingTimeOfTerm;
    uint256 public currentSupply;
    uint256 public currentTerm;
    uint256 public lastTermClosed;
    uint256 public rewardIndex;
    address public treasury;
    uint256 public undistributedRewards;

    error Stake_InvalidAmount();
    error Unstake_NotEnoughAmountStaked();
    error Unstake_InvalidAmount();
    error Unstake_StakeLocked();
    error CreateNewSupply_NotEnoughVolume();
    error CheckTerm_WrongTerm();
    error RewardStaker_NoRewardPending();
    error RewardStaker_NoTokenStaked();
    error CheckTerm_NoTokenStaked();

    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);
    event AccountRewarded(address account);

    modifier CheckTerm() {
        if (block.timestamp > startingTimeOfTerm + LOCK_PERIOD) {
            if (currentTerm > lastTermClosed) {
                startingTimeOfTerm = block.timestamp;
                uint256 amountToMint = (currentSupply * 10) / 100;
                if (volumePerTerm >= amountToMint) {
                    currentSupply = totalSupply();
                    _mint(address(this), amountToMint);
                    if (totalStaked > 0) {
                        rewardIndex += (amountToMint * PRECISION) / totalStaked;
                    } else {
                        undistributedRewards += amountToMint;
                    }
                }
                _startNewTerm();
            }
        }
        _;
    }

    constructor(address _treasury) ERC20("Tokenomics", "TKN") {
        treasury = _treasury;
        _mint(treasury, INITIAL_SUPPLY);
        currentSupply = totalSupply();
        startingTimeOfTerm = block.timestamp;
        volumePerTerm = 0;
        currentTerm++;
    }

    function stake(uint256 amount) external CheckTerm {
        if (amount == 0) revert Stake_InvalidAmount();
        _accreditRewards(msg.sender);
        stakedPerAccount[msg.sender].amount += amount;
        stakedPerAccount[msg.sender].lockedUntil =
            block.timestamp +
            LOCK_PERIOD;
        totalStaked += amount;
        volumePerTerm += amount;
        _transfer(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external CheckTerm {
        if (amount == 0) revert Unstake_InvalidAmount();
        if (block.timestamp < stakedPerAccount[msg.sender].lockedUntil)
            revert Unstake_StakeLocked();
        if (stakedPerAccount[msg.sender].amount < amount)
            revert Unstake_NotEnoughAmountStaked();
        _accreditRewards(msg.sender);
        stakedPerAccount[msg.sender].amount -= amount;
        totalStaked -= amount;
        volumePerTerm += amount;
        _transfer(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function _startNewTerm() internal {
        currentTerm++;
        lastTermClosed++;
        volumePerTerm = 0;
    }

    function _accreditRewards(address account) internal {
        StakePosition storage s = stakedPerAccount[account];
        uint256 delta = rewardIndex - s.userRewardIndex;
        if (delta > 0 && s.amount > 0) {
            uint256 pending = (s.amount * delta) / PRECISION;
            if (pending > 0) {
                _transfer(address(this), account, pending);
                emit AccountRewarded(account);
            }
        }
        s.userRewardIndex = rewardIndex;
    }
}
