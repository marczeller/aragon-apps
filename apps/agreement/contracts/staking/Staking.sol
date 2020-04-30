pragma solidity 0.4.24;

import "../Agreement.sol";

import "@aragon/os/contracts/common/Autopetrified.sol";
import "@aragon/os/contracts/common/IsContract.sol";
import "@aragon/os/contracts/common/SafeERC20.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";


contract Staking is IsContract {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    string internal constant ERROR_SENDER_NOT_TOKEN = "AGR_STK_SENDER_NOT_COL_TOKEN";
    string internal constant ERROR_SENDER_NOT_AGREEMENT = "AGR_STK_SENDER_NOT_AGREEMENT";
    string internal constant ERROR_INVALID_UNSTAKE_AMOUNT = "AGR_STK_INVALID_UNSTAKE_AMOUNT";
    string internal constant ERROR_NOT_ENOUGH_AVAILABLE_STAKE = "AGR_STK_NOT_ENOUGH_AVAIL_STAKE";
    string internal constant ERROR_AVAILABLE_BALANCE_BELOW_COLLATERAL = "AGR_STK_AVAIL_BAL_BELOW_COL_AMT";
    string internal constant ERROR_COLLATERAL_TOKEN_TRANSFER_FAILED = "AGR_STK_COL_TOKEN_TRANSFER_FAIL";

    event Staked(address indexed signer, uint256 amount);
    event Unstaked(address indexed signer, uint256 amount);
    event Locked(address indexed signer, uint256 amount);
    event Unlocked(address indexed signer, uint256 amount);
    event Slashed(address indexed signer, uint256 amount);
    event CollateralAmountChanged(uint256 previousCollateralAmount, uint256 currentCollateralAmount);

    struct Stake {
        uint256 available;              // Amount of staked tokens that are available to be used by the owner
        uint256 locked;                 // Amount of staked tokens that are locked for the owner
    }

    modifier onlyAgreement() {
        require(msg.sender == address(agreement), ERROR_SENDER_NOT_AGREEMENT);
        _;
    }

    Agreement public agreement;
    ERC20 public collateralToken;
    uint256 public collateralAmount;

    mapping (address => Stake) private stakes;

    /**
    * @notice Create staking with Agreement app `_agreement` and collateral `@tokenAmount(_collateralToken: address, _collateralAmount)`
    * @param _agreement Agreement instance managing the staking
    * @param _collateralToken Address of the ERC20 token to be used for staking
    * @param _collateralAmount Minimum amount of `collateralToken` that will be allowed to stake in the contract
    */
    constructor(Agreement _agreement, ERC20 _collateralToken, uint256 _collateralAmount) public {
        agreement = _agreement;
        collateralToken = _collateralToken;
        collateralAmount = _collateralAmount;
    }

    /**
    * @notice Stake `@tokenAmount(self.collateralToken(): address, _amount)` tokens for `msg.sender`
    * @param _amount Number of tokens to be staked
    */
    function stake(uint256 _amount) external {
        _stake(msg.sender, msg.sender, _amount);
    }

    /**
    * @notice Stake `@tokenAmount(self.collateralToken(): address, _amount)` tokens from `msg.sender` for `_user`
    * @param _user Address staking the tokens for
    * @param _amount Number of tokens to be staked
    */
    function stakeFor(address _user, uint256 _amount) external {
        _stake(msg.sender, _user, _amount);
    }

    /**
    * @dev Callback of `approveAndCall`, allows staking directly with a transaction to the token contract
    * @param _from Address making the transfer
    * @param _amount Amount of tokens to transfer
    * @param _token Address of the token
    */
    function receiveApproval(address _from, uint256 _amount, address _token, bytes /* _data */) external {
        require(msg.sender == _token && _token == address(collateralToken), ERROR_SENDER_NOT_TOKEN);
        _stake(_from, _from, _amount);
    }

    /**
    * @notice Unstake `@tokenAmount(self.collateralToken(): address, _amount)` tokens from `msg.sender`
    * @param _amount Number of tokens to be unstaked
    */
    function unstake(uint256 _amount) external {
        require(_amount > 0, ERROR_INVALID_UNSTAKE_AMOUNT);
        _unstake(msg.sender, _amount);
    }

    /**
    * @notice Lock `@tokenAmount(self.collateralToken(): address, _amount)` tokens for `_user`
    * @param _user Address whose tokens are being locked
    * @param _amount Number of tokens to be locked
    */
    function lock(address _user, uint256 _amount) external onlyAgreement {
        _lock(_user, _amount);
    }

    /**
    * @notice Unlock `@tokenAmount(self.collateralToken(): address, _amount)` tokens for `_user`
    * @param _user Address whose tokens are being unlocked
    * @param _amount Number of tokens to be unlocked
    */
    function unlock(address _user, uint256 _amount) external onlyAgreement {
        _unlock(_user, _amount);
    }

    /**
    * @notice Unlock `@tokenAmount(self.collateralToken(): address, _unlockAmount)` tokens for `_user`, and
    * @notice slash `@tokenAmount(self.collateralToken(): address, _slashAmount)` for `_user` in favor of `_beneficiary`
    * @param _user Address whose tokens are being unlocked and slashed
    * @param _unlockAmount Number of tokens to be unlocked
    * @param _beneficiary Address receiving the slashed tokens
    * @param _slashAmount Number of tokens to be slashed
    */
    function unlockAndSlash(address _user, uint256 _unlockAmount, address _beneficiary, uint256 _slashAmount) external onlyAgreement {
        _unlock(_user, _unlockAmount);
        _slash(_user, _beneficiary, _slashAmount);
    }

    /**
    * @notice Slash `@tokenAmount(self.collateralToken(): address, _amount)` tokens for `_user` in favor of `_beneficiary`
    * @param _user Address being slashed
    * @param _beneficiary Address receiving the slashed tokens
    * @param _amount Number of tokens to be slashed
    */
    function slash(address _user, address _beneficiary, uint256 _amount) external onlyAgreement {
        _slash(_user, _beneficiary, _amount);
    }

    /**
    * @notice Change collateral amount to `@tokenAmount(self.collateralToken(): address, _collateralAmount)`
    * @param _collateralAmount New collateral amount to be used for staking
    */
    function changeCollateralAmount(uint256 _collateralAmount) external onlyAgreement {
        collateralAmount = _collateralAmount;
        emit CollateralAmountChanged(collateralAmount, _collateralAmount);
    }

    /**
    * @dev Tell the information related to a user stake
    * @param _user Address being queried
    * @return available Amount of staked tokens that are available to schedule actions
    * @return locked Amount of staked tokens that are locked due to a scheduled action
    */
    function getBalance(address _user) external view returns (uint256 available, uint256 locked) {
        Stake storage balance = stakes[_user];
        available = balance.available;
        locked = balance.locked;
    }

    /**
    * @dev Stake tokens for a user
    * @param _from Address paying for the staked tokens
    * @param _user Address staking the tokens for
    * @param _amount Number of tokens to be staked
    */
    function _stake(address _from, address _user, uint256 _amount) internal {
        Stake storage balance = stakes[_user];
        uint256 newAvailableBalance = balance.available.add(_amount);
        require(newAvailableBalance >= collateralAmount, ERROR_AVAILABLE_BALANCE_BELOW_COLLATERAL);

        balance.available = newAvailableBalance;
        _transferCollateralTokensFrom(_from, _amount);
        emit Staked(_user, _amount);
    }

    /**
    * @dev Unstake tokens for a user
    * @param _user Address unstaking the tokens from
    * @param _amount Number of tokens to be unstaked
    */
    function _unstake(address _user, uint256 _amount) internal {
        Stake storage balance = stakes[_user];
        uint256 availableBalance = balance.available;
        require(availableBalance >= _amount, ERROR_NOT_ENOUGH_AVAILABLE_STAKE);

        uint256 newAvailableBalance = availableBalance.sub(_amount);
        require(newAvailableBalance == 0 || newAvailableBalance >= collateralAmount, ERROR_AVAILABLE_BALANCE_BELOW_COLLATERAL);

        balance.available = newAvailableBalance;
        _transferCollateralTokens(_user, _amount);
        emit Unstaked(_user, _amount);
    }

    /**
    * @dev Lock a number of available tokens for a user
    * @param _user Address whose tokens are being locked
    * @param _amount Number of tokens to be locked
    */
    function _lock(address _user, uint256 _amount) internal {
        Stake storage balance = stakes[_user];
        uint256 availableBalance = balance.available;
        require(availableBalance >= _amount, ERROR_NOT_ENOUGH_AVAILABLE_STAKE);

        balance.available = availableBalance.sub(_amount);
        balance.locked = balance.locked.add(_amount);
        emit Locked(_user, _amount);
    }

    /**
    * @dev Unlock a number of locked tokens for a user
    * @param _user Address whose tokens are being unlocked
    * @param _amount Number of tokens to be unlocked
    */
    function _unlock(address _user, uint256 _amount) internal {
        Stake storage balance = stakes[_user];
        balance.locked = balance.locked.sub(_amount);
        balance.available = balance.available.add(_amount);
        emit Unlocked(_user, _amount);
    }

    /**
    * @dev Slash a number of locked tokens for a user
    * @param _user Address whose tokens are being slashed
    * @param _beneficiary Address receiving the slashed tokens
    * @param _amount Number of tokens to be slashed
    */
    function _slash(address _user, address _beneficiary, uint256 _amount) internal {
        Stake storage balance = stakes[_user];
        balance.locked = balance.locked.sub(_amount);
        _transferCollateralTokens(_beneficiary, _amount);
        emit Slashed(_user, _amount);
    }

    /**
    * @dev Transfer collateral tokens to an address
    * @param _to Address receiving the tokens being transferred
    * @param _amount Number of collateral tokens to be transferred
    */
    function _transferCollateralTokens(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            require(collateralToken.safeTransfer(_to, _amount), ERROR_COLLATERAL_TOKEN_TRANSFER_FAILED);
        }
    }

    /**
    * @dev Transfer collateral tokens from an address to the Agreement app
    * @param _from Address transferring the tokens from
    * @param _amount Number of collateral tokens to be transferred
    */
    function _transferCollateralTokensFrom(address _from, uint256 _amount) internal {
        if (_amount > 0) {
            require(collateralToken.safeTransferFrom(_from, address(this), _amount), ERROR_COLLATERAL_TOKEN_TRANSFER_FAILED);
        }
    }
}
