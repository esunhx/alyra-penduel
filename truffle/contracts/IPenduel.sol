// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Penduel.sol";

library States {
    enum GameState {
        Created,
        Active,
        Finished
    }
}

interface IPenduel {
    function setWord(string memory wordToGuess) external;
    function setState(States.GameState state) external;
    function setOpponent(address opponent) external;
    function getPlayer() external view returns (address);
}