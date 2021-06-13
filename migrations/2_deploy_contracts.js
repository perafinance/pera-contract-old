const Pera = artifacts.require("./PERASmartContract.sol");

module.exports = function (deployer) {
  deployer.deploy(Pera,"100","PERA","PERA");
};
