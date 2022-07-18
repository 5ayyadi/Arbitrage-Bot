const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");



describe("Price contract", function () {
  async function deployPriceFixture() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const Price = await ethers.getContractFactory("Price");
    const [owner] = await ethers.getSigners();
    const priceContract = await Price.deploy(WETH);
    await priceContract.deployed();

    return { Price, priceContract, owner };
  }

  describe("Deployment", function () {
    it("Should calculate prices correctly", async function () {
      const { priceContract } = await loadFixture(deployPriceFixture);
      const pairs = ["0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852",
                     "0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11",
                     "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc"];
      const etherPrice = await priceContract.ethPrice(pairs);
      // ether price in that time
      expect(etherPrice).to.equal(1138974)
    });
  });

});