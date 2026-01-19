// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tokenomics is ERC20 {
    struct StakePosition {
        uint256 amount;
        uint256 lockedUntil;
    }

    mapping(address => StakePosition) public stakedPerAccount;
    uint256 totalStaked;
    uint256 public constant INITIAL_SUPPLY = 100000 ether;
    uint256 public constant LOCK_PERIOD = 100800; //14 days
    uint256 public volumePerTerm;
    uint256 public startingTimeOfTerm;

    error Stake_InvalidAmount();
    error Unstake_NotEnoughAmountStaked();
    error Unstake_InvalidAmount();
    error Unstake_StakeLocked();
    error CreateNewSupply_NotEnoughVolume();

    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);

    constructor() ERC20("Tokenomics", "TKN") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function createNewSupply() public {
        uint256 total = totalSupply();
        uint256 adition = (total * 5) / 100;
        if (volumePerTerm < adition) revert CreateNewSupply_NotEnoughVolume();
        _mint(address(this), adition);
    }

    function stake(uint256 amount) external {
        if (amount == 0) revert Stake_InvalidAmount();
        stakedPerAccount[msg.sender].amount += amount;
        stakedPerAccount[msg.sender].lockedUntil = block.number + LOCK_PERIOD;
        totalStaked += amount;
        volumePerTerm += amount;
        _transfer(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        if (amount == 0) revert Unstake_InvalidAmount();
        if (block.number < stakedPerAccount[msg.sender].lockedUntil)
            revert Unstake_StakeLocked();
        if (stakedPerAccount[msg.sender].amount < amount)
            revert Unstake_NotEnoughAmountStaked();
        stakedPerAccount[msg.sender].amount -= amount;
        totalStaked -= amount;
        volumePerTerm += amount;
        _transfer(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }
}
