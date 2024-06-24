//  SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IToken {
    function decimals() external pure returns (uint8);

    function _mint(address _to, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool);

}

/**
 * @title TokenVesting  contract
 * @dev This is the vesting contract  for Token tokens allocated to the team with a ciff period of 6 months i.e. 180days and 
 * a vesting cycle of 4years where equal number of tokens are available to mint each day.
 */



contract TokenVesting {
    ///////////////////
    // Errors
    ///////////////////
    error TokenVesting_NotOwner();
    error TokenVesting_NotValidAddress();
    error TokenVesting_NotEOA();

    ///////////////////
    // State Variables
    ///////////////////
    /** 
    * @dev The address of token token will be pass as contract in production
    */
    // address public constant tokenAddress = 0x7b96aF9Bd211cBf6BA5b0dd53aa61Dc5806b6AcE;         //Address of Token token
    // IToken constant token = IToken(tokenAddress);
    // uint256 decimalFactor = 10**uint256(token.decimals());
    IToken public token;
    address public s_owner;
    uint256 public i_deployedAt;
    uint256 public totalBalanceOfContract;

    ///////////////////
    // Types
    ///////////////////
    struct VestingDetails {
        uint256 startTime;
        uint256 lockTime;
        uint256 endTime;
        uint256 totalAllocationAmount;
        uint256 mintedAmount;
        uint256 withdrawableAmountInContract;
        uint256 transferedAmount;
        address assignedAddress;
    }

    VestingDetails public VestingDetailsTeam;
  
    ///////////////////
    // Events
    ///////////////////
    event mintToken(uint256 mintAmount, uint256 mintTime);
    event transferToken(
        address indexed assignedAddress,
        uint256 transferAmount,
        uint256 transfertime
    );

    ///////////////////
    // Modifiers
    ///////////////////
    modifier onlyOwner() {
        if (msg.sender != s_owner) revert TokenVesting_NotOwner();
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(address tokenAddress) {
        token = IToken(tokenAddress);
        uint256 decimalFactor = 10**uint256(token.decimals());
        s_owner = msg.sender;
        i_deployedAt = block.timestamp;
        //Team Details
        VestingDetailsTeam = VestingDetails({
            startTime: block.timestamp + 180 days, // clif period 6 months = 180 days
            lockTime: block.timestamp + 181 days,
            endTime: block.timestamp + 1460 days, 
            totalAllocationAmount: 100000000 * decimalFactor,
            mintedAmount: 0,
            withdrawableAmountInContract: 0,
            transferedAmount: 0,
            /// @dev initialy no address is assigned
            assignedAddress: address(0)
        });
    }


    /*
      @param assignAddress: Address to assigned for vesting team allocated tokens
     */
    function addVestingAddressTeam(address assignAddress) external onlyOwner {
        require(
            VestingDetailsTeam.assignedAddress == address(0),
            "Already Assigned!"
        );
        require(assignAddress != address(0),"Can't assign zero address");
        VestingDetailsTeam.assignedAddress = assignAddress;
    }


    /**
     * @notice this function is used to view the tokens available for mint for team allocation
     */
    function checkMintableTeamFunds() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 startTime = VestingDetailsTeam.startTime;
        uint256 lockTime = VestingDetailsTeam.lockTime;
        uint256 endTime = VestingDetailsTeam.endTime;

        if (currentTime < lockTime) {
            return 0;
        } else if (currentTime >= endTime) {
            return (VestingDetailsTeam.totalAllocationAmount -
                VestingDetailsTeam.mintedAmount);
        } else {
            uint256 numberOfdays = ((currentTime - startTime) / 1 days);
            uint256 unlockedTokens = ((VestingDetailsTeam
                .totalAllocationAmount / 1280) * numberOfdays);
            return ((unlockedTokens - VestingDetailsTeam.mintedAmount));
        }
    }


    /**
     @param mintAmount: Amount to mint to the assigned team address
     */
    function mintTeamRewards(uint256 mintAmount) public onlyOwner{
        require(
            VestingDetailsTeam.assignedAddress != address(0),
            "First assign address to team for minting tokens"
        );
        require(
            VestingDetailsTeam.totalAllocationAmount >=
                (VestingDetailsTeam.mintedAmount + mintAmount),
            "Amount is more than allocated amount"
        );

        uint256 currentTime = block.timestamp;
        uint256 startTime = VestingDetailsTeam.startTime;
        uint256 lockTime = VestingDetailsTeam.lockTime;
        uint256 endTime = VestingDetailsTeam.endTime;

        require(currentTime >= lockTime, "Funds are not unlocked yet");

        if (currentTime >= endTime) {
            token._mint(address(this), mintAmount);
            VestingDetailsTeam.mintedAmount += mintAmount;
            VestingDetailsTeam.withdrawableAmountInContract += mintAmount;
            totalBalanceOfContract += mintAmount;

            emit mintToken(mintAmount, block.timestamp);
        } else {
            uint256 numberOfdays = ((currentTime - startTime) / 1 days);
            uint256 unlockedTokens = ((VestingDetailsTeam
                .totalAllocationAmount / 1280) * numberOfdays);
            require(
                mintAmount <= unlockedTokens,
                "Input is more than unlocked tokens!!!"
            );
            token._mint(address(this), mintAmount);
            VestingDetailsTeam.mintedAmount += mintAmount;
            VestingDetailsTeam.withdrawableAmountInContract += mintAmount;
            totalBalanceOfContract += mintAmount;
            emit mintToken(mintAmount, block.timestamp);
        }
    }

    
    /**
     * @param amount: Amount to transfer to the assigned address
     * @dev This function should only be called after calling the mintTeamRewards
             to tranfer the minted rewards from contract to the assigned address
     */
    function transferTeamFundsToAddress(uint256 amount)public onlyOwner returns (bool) {
        require(
            amount <= VestingDetailsTeam.withdrawableAmountInContract,
            "Transfer amount is more than current allocation amount"
        );
        bool staus = token.transfer(VestingDetailsTeam.assignedAddress, amount);

        VestingDetailsTeam.withdrawableAmountInContract -= amount;
        VestingDetailsTeam.transferedAmount += amount;
        totalBalanceOfContract -= amount;

        emit transferToken(
            VestingDetailsTeam.assignedAddress,
            amount,
            block.timestamp
        );
        return staus;
    }

   
}
