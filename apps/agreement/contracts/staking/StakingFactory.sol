pragma solidity ^0.4.24;

import "./Staking.sol";
import "../Agreement.sol";

import "@aragon/os/contracts/lib/token/ERC20.sol";


contract StakingFactory {
    event NewStaking(Agreement indexed agreement, Staking indexed staking);

    constructor() public {}

    function createInstance(ERC20 _token, uint256 _amount) external returns (Staking) {
        Agreement agreement = Agreement(msg.sender);
        Staking staking = new Staking(agreement, _token, _amount);
        emit NewStaking(agreement, staking);
        return staking;
    }
}
