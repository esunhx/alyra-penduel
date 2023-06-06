const Penduel = artifacts.require('Penduel');

contract('Penduel', function (accounts) {
  const player1 = accounts[0];
  const player2 = accounts[1];
  const STAKE = 10;
  const CREATION_TIME = Math.floor(Date.now() / 1000);
  const JOINED_TIME = CREATION_TIME + 3600; 
  const answer = web3.utils.fromAscii('testword');
  let instance;

  before(async function () {
    instance = await Penduel.new(player1, STAKE, { value: STAKE / 2 });
  });

  it('should set the word', async function () {
    await instance.setWord(answer);
    const revealed = await instance.revealed.call();
    assert.equal(revealed, '0x0000000000000000000000000000000000000000000000000000000000000000');
  });

  it('should set the opponent', async function () {
    await instance.setOpponent(player2);
    const joinedTime = await instance.JOINED_TIME.call();
    assert.equal(joinedTime, JOINED_TIME);
  });

  it('should make a letter guess', async function () {
    await instance.makeGuess(116); 
    const gameState = await instance.penduelState.call();
    const revealed = await instance.revealed.call();
    assert.equal(gameState, 2); 
    assert.equal(revealed, '0x0000000000000000000000000000000000000000000000000100000000000000');
  });

  it('should make a word guess', async function () {
    await instance.makeGuess(answer);
    const gameState = await instance.penduelState.call();
    assert.equal(gameState, 3); 
  });
});
