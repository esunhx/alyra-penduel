// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./../node_modules/@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./../node_modules/@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./../node_modules/@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract VRFConsumer is VRFConsumerBaseV2, ConfirmedOwner {
    uint64 immutable internal subId;
    bytes32 immutable internal keyHash;
    uint32 immutable internal callbackGasLimit;
    uint16 immutable internal requestConfirmations;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface internal immutable LINKTOKEN;

    event RequestSent(uint256 indexed requestId, uint32 numWords);
    event RequestFulfilled(uint256 indexed requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 numWords;

    constructor(
        address _coordinatorAddr,
        address _linkTokenContract,
        uint64 _subId, 
        bytes32 _keyHash, 
        uint32 _callbackGasLimit, 
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(_coordinatorAddr) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(_coordinatorAddr);
        LINKTOKEN = LinkTokenInterface(_linkTokenContract);
        subId = _subId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash, 
            subId, 
            requestConfirmations, 
            callbackGasLimit, 
            numWords
        );
        requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId, 
        uint256[] memory _randomWords
    ) internal override onlyOwner {
        require(requests[_requestId].exists, "Request not found");
        requests[_requestId].fulfilled = true;
        requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view onlyOwner returns (bool fulfilled, uint256[] memory randomWords) {
        require(requests[_requestId].exists, "Request not found");
        RequestStatus memory request = requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function topUpSubscription(uint256 _amount) external onlyOwner {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            _amount,
            abi.encode(subId)
        );
    }
}