pragma solidity 0.4.24;

import "../../Agreement.sol";
import "./TimeHelpersMock.sol";


contract AgreementMock is Agreement, TimeHelpersMock {
    /**
    * @dev Tell whether an address can challenge actions or not
    * @param _challenger Address being queried
    * @return True if the given address can challenge actions, false otherwise
    */
    function canChallenge(address _challenger) external view returns (bool) {
        return _canChallenge(_challenger);
    }

    /**
    * @dev Tell whether an action can be cancelled or not
    * @param _actionId Identification number of the action to be queried
    * @return True if the action can be cancelled, false otherwise
    */
    function canCancel(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canCancel(action);
    }

    /**
    * @dev Tell whether an action can be challenged or not
    * @param _actionId Identification number of the action to be queried
    * @return True if the action can be challenged, false otherwise
    */
    function canChallengeAction(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canChallengeAction(action);
    }

    /**
    * @dev Tell whether an action can be settled or not
    * @param _actionId Identification number of the action to be queried
    * @return True if the action can be settled, false otherwise
    */
    function canSettle(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canSettle(action);
    }

    /**
    * @dev Tell whether an action can be disputed or not
    * @param _actionId Identification number of the action to be queried
    * @return True if the action can be disputed, false otherwise
    */
    function canDispute(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canDispute(action);
    }

    /**
    * @dev Tell whether an action settlement can be claimed or not
    * @param _actionId Identification number of the action to be queried
    * @return True if the action settlement can be claimed, false otherwise
    */
    function canClaimSettlement(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canClaimSettlement(action);
    }

    /**
    * @dev Tell whether an action dispute can be ruled or not
    * @param _actionId Identification number of the action to be queried
    * @return True if the action dispute can be ruled, false otherwise
    */
    function canRuleDispute(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canRuleDispute(action);
    }

    /**
    * @dev Tell whether an action can be executed or not
    * @param _actionId Identification number of the action to be queried
    * @return True if the action can be executed, false otherwise
    */
    function canExecute(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canExecute(action);
    }
}
