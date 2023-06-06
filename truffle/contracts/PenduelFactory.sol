// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";

import "./Penduel.sol";
import "./IPenduel.sol";
import "./VRFConsumer.sol";
import "./IVRFConsumer.sol";

/**
 * @author  Ascanio Macchi di Cellere
 * @title   Penduel Games Factory
 * @dev     A contract for creating Penduel instances and control ChainLink
 subscription.
 */

contract PenduelFactory is Ownable {
    address immutable public VRFConsumerAddr;
    mapping (uint256 => address) internal games;

    event NewGame(uint256 indexed requestId, address indexed player);
    event JoinedGame(uint256 indexed requestId, address indexed opponent);
    event PlayerReconnected(uint256 indexed requestId, address indexed playerOrOpponent);

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

    /**
     * @dev     Function to instantiate VRFConsumer contract to request random
     word inputs for Penduel instances and manage subscription.
     * @param   _coordinatorAddr  Address of the ChainLink VRF coordinator contract.
     * @param   _linkTokenContract  Address of the link token contract.
     * @param   _subId  ChainLink subscirption ID.
     * @param   _keyHash  The gas lane to use, specifies max gas price.
     * @param   _callbackGasLimit  Limit of how much gas to use for fulfillRandomWords
     callback function, from the VRF consumer contract.
     * @param   _requestConfirmations  Number of confirmations the ChainLink node will
     execute. Higher values will provide greater randomness confidence. 
     * @return  address  Address of the VRF consumer contract bound to this contract.
     */
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

    /**
     * @dev     Function to request a random word and initiate a Penduel game.
     * @param   _stake  The initial bet from the creator of the Penduel instance,
     multiplied by 2.
     */
    function requestGame(uint256 _stake) external payable {
        uint256 requestId = IVRFConsumer(VRFConsumerAddr).requestRandomWords();
        (
            bool fulfilled, 
            uint256[] memory randomWords
        ) = IVRFConsumer(VRFConsumerAddr).getRequestStatus(requestId);
        require(fulfilled, "Random words request not yet fulfilled");
        createGame(_stake, requestId, randomWords[0]);
    }

    /**
     * @dev     Function to create a Penduel contract instance and set the word
     to guess, obtained through VRF randomness request.
     * @param   _stake  The stake to win from a Penduel game.
     * @param   _requestId  The request ID associated with the word to guess of 
     such given Penduel instance.
     * @param   _word  The randomly generated word to guess.
     */
    function createGame(uint256 _stake, uint256 _requestId, uint256 _word) internal {
        address payable player = payable(msg.sender);
        games[_requestId] = address(
            (new Penduel){ value: msg.value}(player, _stake)
        );
        IPenduel(games[_requestId]).setWord(_word);
        IPenduel(games[_requestId]).setTimer(0);
        emit NewGame(_requestId, msg.sender);
    }

    /**
     * @dev     Function to allow a second player to join a Penduel game instance.
     * @param   _requestId  Id associated with a VRF request for a random
     generated word, associated with an existing Penduel instance.
     */
    function joinGame(uint256 _requestId) external payable {
        require(games[_requestId] != address(0), "Game does not exists!");
        require(
            msg.sender != IPenduel(games[_requestId]).getPlayer(), 
            "Player already joined this game"
        );
        (bool success,) = games[_requestId].call{value: msg.value}("");
        require(success, "Unable to pay for the transaction");
        address payable opponent = payable(msg.sender);
        IPenduel(games[_requestId]).setOpponent(opponent);
        IPenduel(games[_requestId]).setTimer(1);
        emit JoinedGame(_requestId, msg.sender);
    }

    /**
     * @dev     Function to reconnect a player to an existing Penduel game instance,
     which he is already registered with.
     * @param   _requestId Id associated with a VRF request for a random
     generated word, associated with an existing Penduel instance.
     */
    function joinExistingGame(uint256 _requestId) external {
        require(games[_requestId] != address(0), "Game does not exists!");
        require(
            msg.sender == IPenduel(games[_requestId]).getPlayer() ||
            msg.sender == IPenduel(games[_requestId]).getOpponent(),
            "Player not recognised for game Id"
        );

        emit PlayerReconnected(_requestId, msg.sender);
    }

    /**
     * @dev     Function to call the startPenduel function of a given
     Penduel instance.
     * @param   _requestId Id associated with a VRF request for a random
     generated word, associated with an existing Penduel instance.
     */
    function beginPenduel(uint256 _requestId) external {
        require(games[_requestId] != address(0), "Game does not exists!");
        require(
            msg.sender == IPenduel(games[_requestId]).getPlayer() ||
            msg.sender == IPenduel(games[_requestId]).getOpponent(),
            "Player not recognised for game Id"
        );
        IPenduel(games[_requestId]).startPenduel(msg.sender);
    }
}