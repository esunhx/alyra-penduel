// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";


/**
 * @author  Ascanio Macchi di Cellere
*/

/**
 * @dev Library to provide access of the GameState enumeration across 
 the factory contract, interface and contract itself.
 */
library States {
    enum GameState {
        Created,
        Active,
        Started,
        Finished
    }
}

/**
 * @title   Penduel
 * @notice  A contract for a word guessing game between two players
 */
contract Penduel is Ownable {
    uint256 immutable public STAKE;
    uint256 immutable public CREATION_TIME;

    uint256 public JOINED_TIME;
    uint256 public START_TIME;
    uint256 internal ACTIVITY_TIME;
    bool public isACTIVE;

    address payable[2] public players;
    mapping (uint8 => bool) guesses;
    bytes32 internal answer;
    bytes32 public revealed;
    bool playerTurn;

    States.GameState public penduelState;

    event GameStarted(address gameAddress, uint256 timeStamp);
    event GuessMade(address playerOrOpponent, string letterOrWord);
    event WinnerIs(address playerOrOpponent, uint256 stake);

    constructor(address payable _player, uint256 _stake) payable {
        require(msg.value == _stake/2, "Bet not proportional to stake");
        CREATION_TIME = block.timestamp;
        STAKE = _stake;
        isACTIVE = true;
        players[0] = _player;
        penduelState = States.GameState.Created;
    }

    /**
     * @dev Modifier to ensure game calls are only made by players.
     */
    modifier onlyPlayers() {
        require(
            msg.sender == players[0] || msg.sender == players[1],
            "Unrecognised address"
        );
        _;
    }

    /**
     * @dev Modifier to ensure function calls are only made by either players
     or owner of such contract.
     */
    modifier onlyAuthorised() {
        require(
            msg.sender == players[0] || 
            msg.sender == players[1] ||
            msg.sender == owner(),
            "Unathorised address"
        );
        _;
    }

    /**
     * @dev     Function to set the answer state variable, from the factory,
        which players have to guess in order to win the stake.
     * @param   _wordToGuess  The answer parameter input.
     */
    function setWord(bytes32 _wordToGuess) external onlyOwner {
        require(penduelState == States.GameState.Created);
        answer = toLowerCase(_wordToGuess);
    }

    /**
     * @dev     Function to set the penduelState state variable from the contructor, 
     the factory and within certain functions that affect the state of the game.
     * @param   _state  The penduelState parameter input.
     */
    function setState(States.GameState _state) public onlyAuthorised {
        require(uint(penduelState) >= 0, "Invalid set state operation");
        penduelState = _state;
    }

    /**
     * @dev     Function to set the opponent's address stored within the players state
     variable at index 1. 
     * @param   _opponent  The address of the second player to register for a Penduel
     instance.
     */
    function setOpponent(address payable _opponent) external onlyOwner {
        require(penduelState == States.GameState.Active, "Game is not active");
        require(players[1] == address(0), "Opponent already exists");
        JOINED_TIME = block.timestamp;
        players[1] = _opponent;
    }

    /**
     * @dev     Function to set the ACTIVITY_TIME state variable, only callable by
     the factory contract. The purpose is to have 
     * @param   _endTime  .
     */
    function setTimer(uint256 _endTime) external onlyOwner {
        require(uint(penduelState) >= 0, "Invalid set timer operation");
        if (_endTime == 0 && penduelState == States.GameState.Created) {
            ACTIVITY_TIME = CREATION_TIME + 1 hours;
        } else if (_endTime == 0 && penduelState == States.GameState.Active) {
            ACTIVITY_TIME = JOINED_TIME + 1 days;
        } else {
            ACTIVITY_TIME = START_TIME + _endTime * 7 days;
        }
    }

    /**
     * @dev     Function overload to make a guess for a letter, only callable by
     the players. It is responsible for emitting GuessMade and WinnerIs events,
     necessary for the client side to keep track of the game progress.
     * @param   _letter  The input guess parameter, typed as ASCII char.
     */
    function makeGuess(uint8 _letter) internal onlyPlayers {
        require(penduelState == States.GameState.Started, "Game has not started");
        require(!guesses[_letter], "Letter has already been guessed");
        bytes32 _guess = toLowerCase(bytes32(abi.encodePacked(_letter)));
        guesses[_letter] = true;
        revealed = updateRevealed(_guess);
        if (revealed == answer) {
            setState(States.GameState.Finished);
            if (playerTurn) {
                emit WinnerIs(players[0], STAKE);
            } else {
                emit WinnerIs(players[1], STAKE);
            }
        } else {
            if (playerTurn) {
                emit GuessMade(players[0], string(abi.encodePacked(_guess)));
            } else {
                emit GuessMade(players[1], string(abi.encodePacked(_guess)));
            }
        }
    }

    /**
     * @dev     Function overload to make a guess for a word, only callable by
     the players. It is responsible for emitting GuessMade and WinnerIs events,
     necessary for the client side to keep track of the game progress.
     * @param   _guess  The input guess parameter, typed as bytes32 for storage
     optimisation.
     */
    function makeGuess(bytes32 _guess) internal onlyPlayers {
        require(penduelState == States.GameState.Started, "Game has not started");
        _guess = toLowerCase(_guess);
        if (_guess == answer) {
            setState(States.GameState.Finished);
            if (playerTurn) {
                emit WinnerIs(players[0], STAKE);
            } else {
                emit WinnerIs(players[1], STAKE);
            }
        } else {
            if (playerTurn) {
                emit GuessMade(players[0], string(abi.encodePacked(_guess)));
            } else {
                emit GuessMade(players[1], string(abi.encodePacked(_guess)));
            }
        }
    }

    /**
     * @dev     Fuction to handle each correct player's letter guess, called within 
     the makeGuess function taking uint8 input - ASCII char. A copy of the state var
     revealed is made, the for loop allows to iterate over the answer and compare it
     with the guessed letter. If there is a match, a mask is declared to store the
     position of the guessed letter then the bitwise operator OR is used to update
     the revealed copy. 
     * @param   _letter  The guessed letter from makeGuess(uint8 _letter) converted 
     from ASCII char to bytes32.
     * @return  bytes32  The updated value stored inside the state variable revealed.
     */
    function updateRevealed(bytes32 _letter) internal view onlyPlayers returns (bytes32) {
        bytes32 _revealedCopy = revealed;
        for (uint8 i = 0; i < answer.length; i++) {
            if (answer[i] == _letter) {
                bytes32 _mask = bytes32(uint256(1) << (i*8));
                _revealedCopy = _revealedCopy | _mask;
            }
        }
        return _revealedCopy;
    }

    /**
     * @dev Function to start a game, only callable once the penduelState is set to
     Active and by the addressess stored inside the players state array. It stores
     the time at which a game started and emits an event for clientSide rendering.
     It also sets whether the first or second player started the game, through a boolean
     state variable.
     */
    function startPenduel() external onlyPlayers {
        require(penduelState == States.GameState.Active, "Game is not active");
        setState(States.GameState.Started);
        START_TIME = block.timestamp;
        emit GameStarted(address(this), START_TIME);
        if (msg.sender == players[0]) {
            playerTurn = true;
        } else {
            playerTurn = false;
        }
    }

    /**
     * @dev     Function to play the game, only callable by the players. It handles
     each player's turn logic and calls the adequate makeGuess overload. It also
     calls the handleTimer function, to ensure an homogeneous max play time.
     * @param   _guess  A player's guess, whether simply an ASCII char or a 
     full word.
     */
    function playPenduel(bytes32 _guess) external onlyPlayers {
        require(penduelState == States.GameState.Started, "Game has not started");
        if (playerTurn) {
            require(msg.sender == players[0], "Only player can guess now");
        } else {
            require(msg.sender == players[1], "Only opponent can guess now");
        }
        if (_guess.length == 1) {
            makeGuess(uint8(uint256(_guess)));
        } else {
            makeGuess(_guess);
        }
        handleTimer();
        playerTurn = !playerTurn;
    }

    /**
     * @dev     Function to read the first address stored inside the state array players.
     * @return  address  The address stored at players[0].
     */
    function getPlayer() external view onlyOwner returns (address payable) {
        require(players[0] != address(0), "Player not found");
        return players[0];
    }

    /**
     * @dev     Function to read the second address stored inside the state array players.
     * @return  address  The address stored at players[1].
     */
    function getOpponent() external view onlyOwner   returns (address) {
        require(players[1] != address(0), "Opponent not found");
        return players[1];
    }

    /**
     * @dev     Utility function, used to ensure word comparison. It converts all characters
     winthin a bytes32 input, to lower case characters.
     * @param   _input  A bytes32 representing a single character or a full word.
     * @return  bytes32  The return value will certainly be lower case character or word.
     */
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

    /**
     * @dev Utility function to call the handleActivity function at the right time.
     */
    function handleTimer() internal onlyPlayers() {
        if (block.timestamp >= ACTIVITY_TIME) {
            handleActivity();
        }
    }

    /**
     * @dev Utility function to handle the ACTIVITY_TIME, which determines:
     - the max play time of a Penduel instance or
     - the expiration of a game because an opponent did not join. 
     It sets the state variable isACTIVE to false when a game is finished or 
     has to be terminated. It calls the sendFunds function to return the funds 
     held by a Penduel instance to the appropriate player's address.
     */
    function handleActivity() public onlyAuthorised {
        require(block.timestamp >= ACTIVITY_TIME, "You still got time");
        require(isACTIVE, "Contract is already inactive");
        if (address(this).balance > 0) {
            if (playerTurn || players[1] == address(0)) {
                sendFunds(players[0]);
            } else {
                sendFunds(players[1]);
            }
        }
        isACTIVE = false;
    }

    /**
     * @dev     Utility function to return the funds held by a Penduel instance,
     to a given address, from the state array players.
     * @param   _recipient  One of the two addresses stored inside players.
     */
    function sendFunds(address payable _recipient) internal {
        require(address(this).balance >= STAKE, "Insufficient funds");
        (bool success,) = _recipient.call{value: STAKE}("");
        require(success, "Stake withdrawal failed");
    }
}
