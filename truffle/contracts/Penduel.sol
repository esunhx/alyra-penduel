// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Penduel is Ownable {
    uint256 immutable public STAKE;

    // enum GameState {
    //     Created,
    //     Active,
    //     Finished
    // }

    constructor (address firstPlayer, uint256 _stake) payable {
        transferOwnership(firstPlayer);
        STAKE = _stake;
    }

}
