// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    Ownable2StepUpgradeable,
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

/**
 * @title MonadexPrelaunchPoints.
 * @author Monadex Labs -- mgnfy-view.
 * @notice The points system allows us to reward active and loyal users of our protocol.
 * Points will be convertible to the MDX token (Monadex governance and utility token) after
 * launch.
 */
contract MonadexPrelaunchPoints is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    mapping(address user => uint256 points) private s_pointsAllocated;
    uint256 private s_totalSupply;
    uint256[20] private __; // reserving some space so that we can add variables during an update

    event PointsAllocated(address indexed user, uint256 indexed amount);
    event BatchPointsAllocated(address[] users, uint256[] amounts);
    event Penalized(address user, uint256 amount);
    event BatchPenalized(address[] users, uint256[] amounts);

    error MonadexPrelauncPoints__ArraySizesDoNotMatch();
    error MonadexPrelauncPoints__ExcessPenalty();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Allows the Monadex team (owner) to allocate points to a single user.
     * @param _user The user to allocate points to.
     * @param _amount The amount of points to allcoate.
     */
    function allocatePoints(address _user, uint256 _amount) external onlyOwner {
        s_pointsAllocated[_user] += _amount;
        s_totalSupply += _amount;

        emit PointsAllocated(_user, _amount);
    }

    /**
     * @notice Allows the Monadex team (owner) to allocate points to multiple users.
     * @param _users The users to allocate points to.
     * @param _amounts The amount of points to allocate to users.
     */
    function batchAllocatePoints(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        if (_users.length != _amounts.length) revert MonadexPrelauncPoints__ArraySizesDoNotMatch();
        uint256 length = _users.length;

        for (uint256 count = 0; count < length; ++count) {
            s_pointsAllocated[_users[count]] += _amounts[count];
            s_totalSupply += _amounts[count];
        }

        emit BatchPointsAllocated(_users, _amounts);
    }

    /**
     * @notice Allows the Monadex team to penalize a single user by taking away points from them.
     * @param _user The user to penalize.
     * @param _amount The penalty amount.
     */
    function penalize(address _user, uint256 _amount) external onlyOwner {
        if (s_pointsAllocated[_user] < _amount) revert MonadexPrelauncPoints__ExcessPenalty();

        s_pointsAllocated[_user] -= _amount;
        s_totalSupply -= _amount;

        emit Penalized(_user, _amount);
    }

    /**
     * @notice Allows the Monadex team to penalize multiple users by taking away points from them.
     * @param _users The users to penalize.
     * @param _amounts The penalty amounts.
     */
    function batchPenalize(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        if (_users.length != _amounts.length) revert MonadexPrelauncPoints__ArraySizesDoNotMatch();
        uint256 length = _users.length;

        for (uint256 count = 0; count < length; ++count) {
            if (s_pointsAllocated[_users[count]] < _amounts[count]) revert MonadexPrelauncPoints__ExcessPenalty();

            s_pointsAllocated[_users[count]] -= _amounts[count];
            s_totalSupply -= _amounts[count];
        }

        emit BatchPenalized(_users, _amounts);
    }

    /**
     * @notice Gets the point balance of a user.
     * @param _user The user's address.
     * @return The user's point balance.
     */
    function getPointsAllocatedToUser(address _user) external view returns (uint256) {
        return s_pointsAllocated[_user];
    }

    /**
     * @notice Gets the total point supply.
     * @return The total point supply.
     */
    function getTotalSupply() external view returns (uint256) {
        return s_totalSupply;
    }

    function _authorizeUpgrade(address /* newImplementation */ ) internal override onlyOwner {}
}
