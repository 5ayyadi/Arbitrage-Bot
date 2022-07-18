const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");



describe("Arbitrage contract", function () {
  async function deployArbitrage() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const Arbitrage = await ethers.getContractFactory("Arbitrage");
    const arbitrageContract = await Arbitrage.deploy(WETH);
    await arbitrageContract.deployed();

    return { Arbitrage, arbitrageContract };
  }

  describe("Deployment", function () {
    it("Factories and fees added to storage", async function () {
      const { arbitrageContract } = await loadFixture(deployArbitrage);
      const factories = ["0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac",
                     "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
                     "0xBAe5dc9B19004883d0377419FeF3c2C8832d7d7B"];
      const fees = [997,996,995]
      await arbitrageContract.addFactories(factories, fees);
      const storageFactories = await arbitrageContract.allFactories();
      expect(storageFactories).to.have.members(factories);
      for( let i = 0; i < factories.length; i++){
        expect(fees[i]).to.equal(await arbitrageContract.getFee(factories[i]));
      }
    });
    it("swapUsingStableCoin should make profit", async function () {
      const { arbitrageContract } = await loadFixture(deployArbitrage);
      const factories = ["0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac",
                     "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
                     "0xBAe5dc9B19004883d0377419FeF3c2C8832d7d7B"];
      const fees = [997,996,995];
      await arbitrageContract.addFactories(factories, fees);
      const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
      const amountIn = ethers.utils.parseEther("10")
      const gas = 10 ** 8;
      const gasPercentage = 500;      
      await arbitrageContract.setGasPercent(gasPercentage);
      await arbitrageContract.swapUsingStableCoin(USDT,amountIn,gas);

    });
  });

});