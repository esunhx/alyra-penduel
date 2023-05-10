// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";

library States {
    enum GameState {
        Created,
        Active,
        Started,
        Finished
    }
}

contract Penduel is Ownable {
    uint256 immutable public STAKE;
    uint256 immutable public CREATION_TIME;

    uint256 public JOINED_TIME;
    uint256 internal SELFDESTRUCT_TIME;
    
    address[2] players;
    mapping (uint8 => bool) guesses;
    bytes32 internal answer;
    bytes32 public revealed;
    bool firstPlayerTurn;

    States.GameState public penduelState;

    event GuessMade(address player, string letterOrWord);
    event PlayerIsWinner(address player, uint256 stake);

    constructor(address firstPlayer, uint256 _stake) payable {
        require(msg.value == _stake/2, "Bet not proportional to stake");
        STAKE = _stake;
        CREATION_TIME = block.timestamp;
        players[0] = firstPlayer;
        penduelState = States.GameState.Created;
    }

    modifier onlyPlayers() {
        require(
            msg.sender == players[0] || msg.sender == players[1],
            "Unrecognised address"
        );
        _;
    }

    function setWord(bytes32 _wordToGuess) internal onlyOwner {
        require(penduelState == States.GameState.Created);
        answer = toLowerCase(_wordToGuess);
    }

    function setState(States.GameState _state) public onlyOwner {
        require(uint(penduelState) >= 0, "Invalid set state validation");
        penduelState = _state;
    }

    function setOpponent(address _secondPlayer) external onlyOwner {
        require(penduelState == States.GameState.Active, "Game is not active");
        require(players[1] == address(0), "Opponent already exists");
        JOINED_TIME = block.timestamp;
        players[1] = _secondPlayer;
    }

    function guessLetter(uint8 _letter) internal {
        require(penduelState == States.GameState.Started, "Game has not started");
        require(!guesses[_letter], "Letter has already been guessed");
        bytes32 _guess = toLowerCase(bytes32(abi.encodePacked(_letter)));
        guesses[_letter] = true;
        revealed = updateRevealed(_guess);
        if (revealed == answer) {
            setState(States.GameState.Finished);
            if (firstPlayerTurn) {
                emit PlayerIsWinner(players[0], STAKE);
            } else {
                emit PlayerIsWinner(players[1], STAKE);
            }
        } else {
            if (firstPlayerTurn) {
                emit GuessMade(players[0], string(abi.encodePacked(_guess)));
            } else {
                emit GuessMade(players[1], string(abi.encodePacked(_guess)));
            }
        }
    }

    function guessWord(bytes32 _guess) internal {
        require(penduelState == States.GameState.Started, "Game has not started");
        _guess = toLowerCase(_guess);
        if (_guess == answer) {
            setState(States.GameState.Finished);
            if (firstPlayerTurn) {
                emit PlayerIsWinner(players[0], STAKE);
            } else {
                emit PlayerIsWinner(players[1], STAKE);
            }
        } else {
            if (firstPlayerTurn) {
                emit GuessMade(players[0], string(abi.encodePacked(_guess)));
            } else {
                emit GuessMade(players[1], string(abi.encodePacked(_guess)));
            }
        }
    }

    function updateRevealed(bytes32 _letter) internal view returns (bytes32) {
        bytes32 _revealedCopy = revealed;
        for (uint8 i = 0; i < answer.length; i++) {
            if (answer[i] == _letter) {
                bytes32 _mask = bytes32(uint256(1) << (i*8));
                _revealedCopy = _revealedCopy | _mask;
            }
        }
        return _revealedCopy;
    }

    function getPlayer() external view returns (address) {
        require(players[0] != address(0), "Player not found");
        return players[0];
    }

    function getOpponent() external view returns (address) {
        require(players[1] != address(0), "Opponent not found");
        return players[1];
    }

    function toLowerCase(bytes32 _input) internal pure returns (bytes32) {
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

    // function selfDestruct() external onlyOwner {
    //     require(block.timestamp > SELFDESTRUCT_TIME, "You still have time");
    //     if (firstPlayerTurn) {
    //         selfdestruct(players[0]);
    //     }   
    // }
}
