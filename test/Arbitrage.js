const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");



describe("Arbitrage contract", function () {
  async function deployArbitrage() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const Arbitrage = await ethers.getContractFactory("Arbitrage");
    const arbitrageContract = await Arbitrage.deploy(WETH);
    await arbitrageContract.deployed();
    console.log({"Arbitrage Contract Adddress":arbitrageContract.address})
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
      const factories = [
        "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac", // Sushiswap
        "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f", //UniswapV2
        "0xBAe5dc9B19004883d0377419FeF3c2C8832d7d7B", // Apswap
        "0x75e48C954594d64ef9613AeEF97Ad85370F13807", //sakeswap
        "0x115934131916c8b277dd010ee02de363c09d037c" // shiba
      ];
      const fees = [997,997,998,997,997];
      await arbitrageContract.addFactories(factories, fees);
      const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
      const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      const BUSD = "0x4Fabb145d64652a948d72533023f6E7A623C7C53";
      const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";    
      const StableCoins = [USDT,DAI,BUSD,USDC];
      const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
      const amountIn = ethers.utils.parseEther("10");
      const gas = 10 ** 8;
      const gasPercentage = 500;      
      // console.log({StableCoins})
      const result = await arbitrageContract.find_best_result(StableCoins,WETH,amountIn)
      console.log(result)
      // await arbitrageContract.setGasPercent(gasPercentage);
      // await arbitrageContract.swapUsingStableCoin(USDT,amountIn,gas);

    });
  });

});