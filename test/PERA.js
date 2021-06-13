const PERA = artifacts.require("PERA");


contract('PERA', async accounts => {
 const name = 'PERA';
 const symbol = 'PERA';
 const account_two = '0x4fEA81154E69729282E96b0E13BEcb519199071e';

 it('has a name', async function () {
    let instance = await PERA.deployed();
    expect(await instance.name()).to.equal(name);
  });

 it('has a symbol', async function () {
    let instance = await PERA.deployed();
    expect(await instance.symbol()).to.equal(symbol);
  });

 it('get Number Of Holders', async function () {
    let instance = await PERA.deployed();
    let numberOfHolders = await instance.numberofholders();
    console.log(numberOfHolders);
  });


it('show Block Number', async function () {
    let instance = await PERA.deployed();
    let showBlockNumber = await instance.showBnum();
  });

it('checkUsersLP', async function () {
    let instance = await PERA.deployed();
    let checkUsersLPValue = instance.checkusersLP.call(account_two);
  });

PERA.deployed().then(function(instance) { return instance.genesisBlock() }).then(function (value) {
   assert.ok(value,"Example Genesis Block");
});


});
