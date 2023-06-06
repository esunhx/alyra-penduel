// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Penduel.sol";

interface IPenduel {
    function setWord(uint256 wordToGuess) external;
    function setState(States.GameState state) external;
    function setOpponent(address opponent) external;
    function setTimer(uint256 endTime) external;
    function getPlayer() external view returns (address);
    function getOpponent() external view returns (address);
    function startPenduel(address playerOrOpponent) external;
}