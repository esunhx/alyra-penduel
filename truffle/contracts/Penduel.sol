// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";

library States {
    enum GameState {
        Created,
        Active,
        Finished
    }
}

contract Penduel is Ownable {
    uint256 immutable public STAKE;

    address[] players;
    mapping (uint8 => bool) guesses;
    bytes32 answer;
    States.GameState penduelState;

    event GuessMade(address player, string letter);
    event PlayerIsWinner(address player, uint256 stake);

    constructor(address firstPlayer, uint256 _stake) payable {
        require(msg.value == _stake/2, "Bet not proportional to stake");
        STAKE = _stake;
        players.push(firstPlayer);
        penduelState = States.GameState.Created;
    }

    function setWord(bytes32 _wordToGuess) external onlyOwner {

    }

    function setState(States.GameState _state) external onlyOwner {

    }

    function setOpponent(address _secondPlayer) external onlyOwner {
        require(players[1] == address(0), "Opponent already exists");
        players.push(_secondPlayer);
    }

    function guessLetter(uint8 _letter) external {
        require(penduelState == States.GameState.Active, "Game has not started");
        require(!guesses[_letter], "Letter has already been guessed");

        guesses[_letter] = true;

    }

    function getPlayer() external view returns (address) {
        require(players[0] != address(0), "Player not found");
        return players[0];
    }

    function getOpponent() external view returns (address) {
        require(players[1] != address(0), "Opponent not found");
        return players[1];
    }

    function toLowerCase(bytes32 _input) public pure returns (bytes32) {
        bytes memory _inputBytes = abi.encodePacked(_input);
        bytes memory _outputBytes = new bytes(_inputBytes.length);

        for (uint256 i = 0; i < _inputBytes.length; i++) {
            if ((uint8(_inputBytes[i]) >= 65) && (uint8(_inputBytes[i]) <= 90)) {
                _outputBytes[i] = bytes1(uint8(_inputBytes[i]) + 32);
            } else {
                _outputBytes[i] = _inputBytes[i];
            }
        }
        
        return abi.decode(_outputBytes, (bytes32));
    }
}
