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
    it("Should add factories to the storage", async function () {
      const { arbitrageContract } = await loadFixture(deployArbitrage);
      const factories = ["0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac",
                     "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
                     "0xBAe5dc9B19004883d0377419FeF3c2C8832d7d7B"];
      const fees = [997,997,997]
      await arbitrageContract.addFactories(factories, fees);
      const storageFactories = await arbitrageContract.allFactories();
      expect(storageFactories).to.have.members(factories); 
    });
  });

});