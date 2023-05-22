// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";

import "./Penduel.sol";
import "./IPenduel.sol";
import "./VRFConsumer.sol";
import "./IVRFConsumer.sol";

contract PenduelFactory is Ownable {
    address immutable public VRFConsumerAddr;
    mapping (uint256 => address) internal games;

    event NewGame(uint256 indexed requestId, address indexed player);
    event JoinedGame(uint256 indexed requestId, address indexed opponent);

    constructor(
        address _coordinatorAddr,
        address _linkTokenContract,
        uint64 _subId, 
        bytes32 _keyHash, 
        uint32 _callbackGasLimit, 
        uint16 _requestConfirmations
    ) {
        VRFConsumerAddr = createVRFConsumer(
            _coordinatorAddr, 
            _linkTokenContract, 
            _subId, _keyHash, 
            _callbackGasLimit, 
            _requestConfirmations
        );
    }

    function createVRFConsumer(
        address _coordinatorAddr,
        address _linkTokenContract,
        uint64 _subId, 
        bytes32 _keyHash, 
        uint32 _callbackGasLimit, 
        uint16 _requestConfirmations
    ) internal returns (address) {
        return address(
            (new VRFConsumer) (
                _coordinatorAddr,
                _linkTokenContract,
                _subId,
                _keyHash,
                _callbackGasLimit,
                _requestConfirmations
            )
        );
    }

    function createGame(uint256 _stake, uint256 _requestId) external payable {
        address payable player = payable(msg.sender);
        games[_requestId] = address(
            (new Penduel){ value: msg.value}(player, _stake)
        );
    }

    function joinGame(uint256 _requestId) external payable {
        require(games[_requestId] != address(0), "Game does not exists!");
        require(
            msg.sender != IPenduel(games[_requestId]).getPlayer(), 
            ""
        );
        (bool success,) = games[_requestId].call{value: msg.value}("");
        require(success, "Unable to pay for the transaction");
        IPenduel(games[_requestId]).setOpponent(msg.sender);
        emit JoinedGame(_requestId, msg.sender);
    }

    function joinExistingGame() external {}
}