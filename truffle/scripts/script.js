const Penduel = artifacts.require("Penduel");

module.exports = async function () {
  const deployed = await Penduel.deployed();
};
