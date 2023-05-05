// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";
// import "./../node_modules/@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./../node_modules/@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
// import "./../node_modules/@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./../node_modules/@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./Penduel.sol";
import "./IPenduel.sol";

contract PenduelFactory is Ownable, VRFConsumerBase {
    // uint64 immutable subID;
    // VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface internal immutable LINKTOKEN;

    address internal vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    address internal link = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    bytes32 internal keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; //150 gwei

    // uint32 callbackGasLimit = 50000;
    // uint8 confirmations = 7;
    // uint8 numWord = 1;

    // mapping(uint256 => address) private generators;

    mapping(bytes32 => address) internal games;

    event NewGame(bytes32 indexed requestId, address indexed player);
    event JoinedGame(bytes32 indexed requestId, address indexed opponent);

    constructor() VRFConsumerBase(vrfCoordinator, link) {
        // COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        // subID = _subID;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        string memory word = generateWord(randomness);
        IPenduel(games[requestId]).setWord(word);
        IPenduel(games[requestId]).setState(States.GameState.Active);
    }

    function generateWord(uint256 randomness) internal returns (string memory) {

    }

    // function requestRandomWord(uint256)

    function createGame(uint256 _stake) external payable {
        bytes32 requestId = requestRandomness(keyHash, uint256(5));
        games[requestId] = address(
            (new Penduel){ value: msg.value}(msg.sender, _stake)
        );
    }

    function joinGame(bytes32 _requestId) external payable {
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