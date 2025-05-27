import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Crowdfunding
 * @notice A crowdfunding contract that allows users to donate ERC20 tokens to reach a funding goal
 * @dev This contract manages a time-bound crowdfunding campaign with withdrawal capabilities
 */
contract Crowdfunding {
    // CUSTOM ERRORS
    error ZeroAddress();
    error StartTimeInPast();
    error EndTimeBeforeStartTime();
    error ZeroGoal();
    error CampaignNotStarted();
    error CampaignEnded();
    error ZeroAmount();
    error GoalReached();
    error TransferFailed();
    error NoFundsToWithdraw();
    error OnlyCreator();
    error CampaignNotEndedOrGoalNotReached();

    // EVENTS
    /**
     * @notice Emitted when a new donation is made
     * @param donor The address of the donor
     * @param amount The amount donated
     * @param totalDonations The total amount raised after this donation
     */
    event NewDonation(address indexed donor, uint256 amount, uint256 totalDonations);
    
    /**
     * @notice Emitted when a donor withdraws their funds
     * @param donor The address of the donor withdrawing
     * @param amount The amount withdrawn
     * @param totalDonations The total amount raised after withdrawal
     */
    event Withdrawal(address indexed donor, uint256 amount, uint256 totalDonations);
    
    /**
     * @notice Emitted when the creator withdraws the raised funds
     * @param amount The amount withdrawn by the creator
     */
    event CreatorWithdraw(uint256 amount);

    // STORAGE VARIABLES
    /// @notice The timestamp when the campaign starts
    uint256 public startTime;
    
    /// @notice The timestamp when the campaign ends
    uint256 public endTime;
    
    /// @notice The total amount of money raised so far
    uint256 public moneyRaised;
    
    /// @notice The funding goal for the campaign
    uint256 public moneyGoal;
    
    /// @notice The address of the campaign creator
    address public creator;
    
    /// @notice The address of the ERC20 token used for donations
    address public tokenAddress;
    
    /// @notice Mapping of donor addresses to their donation amounts
    mapping(address => uint256) public donors;

    /**
     * @notice Constructor to initialize the crowdfunding campaign
     * @param _creator The address of the campaign creator
     * @param _startTime The timestamp when the campaign starts
     * @param _endTime The timestamp when the campaign ends
     * @param _moneyGoal The funding goal for the campaign
     * @param _tokenAddress The address of the ERC20 token to be used
     */
    constructor(
        address _creator,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _moneyGoal,
        address _tokenAddress
    ) {
        if (_creator == address(0)) revert ZeroAddress();
        if (_startTime <= block.timestamp) revert StartTimeInPast();
        if (_endTime <= _startTime) revert EndTimeBeforeStartTime();
        if (_moneyGoal == 0) revert ZeroGoal();
        if (_tokenAddress == address(0)) revert ZeroAddress();
        
        creator = _creator;
        tokenAddress = _tokenAddress;
        startTime = _startTime;
        endTime = _endTime;
        moneyGoal = _moneyGoal;
    }

    /**
     * @notice Allows users to donate ERC20 tokens to the campaign
     * @param amount The amount of tokens to donate
     * @dev Requires the campaign to be active and not exceed the goal
     */
    function donate(uint256 amount) public {
        if (block.timestamp < startTime) revert CampaignNotStarted();
        if (block.timestamp >= endTime) revert CampaignEnded();
        if (amount == 0) revert ZeroAmount();
        if (moneyRaised + amount > moneyGoal) revert GoalReached();

        moneyRaised += amount;
        donors[msg.sender] += amount;

        if (!IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        emit NewDonation(msg.sender, amount, moneyRaised);
    }

    /**
     * @notice Allows donors to withdraw their funds before the campaign ends
     * @dev Only callable by donors who have contributed and before campaign ends
     */
    function withdrawFunds() public {
        if (block.timestamp >= endTime) revert CampaignEnded();
        if (donors[msg.sender] == 0) revert NoFundsToWithdraw();
        
        uint256 amountToWithdraw = donors[msg.sender];

        moneyRaised -= amountToWithdraw;
        donors[msg.sender] = 0;

        if (!IERC20(tokenAddress).transfer(msg.sender, amountToWithdraw)) {
            revert TransferFailed();
        }
        
        emit Withdrawal(msg.sender, amountToWithdraw, moneyRaised);
    }

    /**
     * @notice Allows the creator to withdraw all raised funds
     * @dev Only callable by creator after campaign ends or goal is reached
     */
    function creatorWithdraw() public {
        if (msg.sender != creator) revert OnlyCreator();
        if (block.timestamp < endTime && moneyRaised != moneyGoal) {
            revert CampaignNotEndedOrGoalNotReached();
        }

        uint256 amountToWithdraw = moneyRaised;
        moneyRaised = 0;

        if (!IERC20(tokenAddress).transfer(creator, amountToWithdraw)) {
            revert TransferFailed();
        }
        
        emit CreatorWithdraw(amountToWithdraw);
    }

    /**
     * @notice Returns the remaining time until campaign ends
     * @return The number of seconds remaining, or 0 if campaign has ended
     */
    function getRemainingTime() public view returns (uint256) {
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }

    /**
     * @notice Returns the remaining amount needed to reach the goal
     * @return The amount still needed to reach the funding goal
     */
    function getRemainingGoal() public view returns (uint256) {
        if (moneyRaised >= moneyGoal) {
            return 0;
        }
        return moneyGoal - moneyRaised;
    }

    /**
     * @notice Checks if the campaign is currently active
     * @return True if the campaign is active, false otherwise
     */
    function isCampaignActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp < endTime;
    }

    /**
     * @notice Checks if the funding goal has been reached
     * @return True if the goal has been reached, false otherwise
     */
    function isGoalReached() public view returns (bool) {
        return moneyRaised >= moneyGoal;
    }
}
