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
    struct TransferRequest {
        address to;
        uint256 amount;
        string description;
    }

    mapping(address user => uint256 points) private s_pointsAllocated;
    uint256 private s_totalSupply;
    /**
     * @dev Users aren't allowed to directly transfer points. However, this is limiting.
     * Users may want to gift points to others, etc. Thus, we introduce a verification
     * queue where users can issue transfer requests, which can be verified and executed
     * by the Monadex team.
     */
    TransferRequest[] private s_verificationQueue;
    uint256 private s_currentIndex;
    uint256[20] private __; // reserving some space so that we can add variables during an update

    event PointsAllocated(address indexed user, uint256 indexed amount);
    event BatchPointsAllocated(address[] users, uint256[] amounts);
    event Penalized(address user, uint256 amount);
    event BatchPenalized(address[] users, uint256[] amounts);
    event TransferRequestIssued(address indexed by, uint256 indexed index);
    event TransferRequestAccepted(uint256 indexed index);
    event BatchTransferRequestsAccepted(uint256[] indices);

    error MonadexPrelauncPoints__ArraySizesDoNotMatch();
    error MonadexPrelauncPoints__ExcessPenalty();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
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
        uint256 length = _users.length - 1;

        while (length >= 0) {
            s_pointsAllocated[_users[length]] += _amounts[length];
            s_totalSupply += _amounts[length];
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
        uint256 length = _users.length - 1;

        while (length >= 0) {
            if (s_pointsAllocated[_users[length]] < _amounts[length]) revert MonadexPrelauncPoints__ExcessPenalty();

            s_pointsAllocated[_users[length]] -= _amounts[length];
            s_totalSupply -= _amounts[length];
        }

        emit BatchPenalized(_users, _amounts);
    }

    /**
     * @notice Allows any user to issue a transfer request. This request will sit in the verification queue
     * until it is accepted by the Monadex team.
     * @param _to The receiver of points.
     * @param _amount The amount to transfer.
     * @param _description A supporting reason for the transfer.
     * @return The index at which the request sits in the verification queue.
     */
    function issueTransferRequest(address _to, uint256 _amount, string memory _description)
        external
        returns (uint256)
    {
        TransferRequest memory transferRequest = TransferRequest({to: _to, amount: _amount, description: _description});
        s_verificationQueue.push(transferRequest);
        uint256 currentIndex = s_currentIndex++;

        emit TransferRequestIssued(msg.sender, currentIndex);

        return currentIndex;
    }

    /**
     * @notice Allows the Monadex team to accept and execute a transfer request.
     * @param _index The index at which the request sits.
     */
    function acceptTransferRequest(uint256 _index) external onlyOwner {
        TransferRequest memory transferRequest = s_verificationQueue[_index];
        s_pointsAllocated[transferRequest.to] += transferRequest.amount;

        emit TransferRequestAccepted(_index);
    }

    /**
     * @notice Allows the Monadex team to accept and execute multiple transfer requests.
     * @param _indices The indices at which the requests sit.
     */
    function batchAcceptTransferRequests(uint256[] memory _indices) external onlyOwner {
        uint256 length = _indices.length;
        TransferRequest memory transferRequest;

        for (uint256 count = 0; count < length; ++count) {
            transferRequest = s_verificationQueue[_indices[count]];
            s_pointsAllocated[transferRequest.to] += transferRequest.amount;
        }

        emit BatchTransferRequestsAccepted(_indices);
    }

    /**
     * @notice Gets the transfer request details at the specified index.
     * @param _index The index at which the transfer request details lie.
     * @return The TransferRequest struct.
     */
    function getTransferRequest(uint256 _index) external view returns (TransferRequest memory) {
        return s_verificationQueue[_index];
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

    /**
     * @notice Gets the transfer request at the specified index.
     * @param _index The index at which the transfer request sits.
     * @return The TransferRequest struct.
     */
    function getTransferRquestAtIndex(uint256 _index) external view returns (TransferRequest memory) {
        return s_verificationQueue[_index];
    }

    /**
     * @notice Gets the current index of the verification queue.
     * @return The current index of the verification queue.
     */
    function getCurrentIndex() external view returns (uint256) {
        return s_currentIndex;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
