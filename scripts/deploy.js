const { ethers } = require("hardhat");
// const hardhat =  require("hardhat");

async function main() {
    //   const currentTimestampInSeconds = Math.round(Date.now() / 1000);
    //   const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    //   const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

    //   const lockedAmount = ethers.utils.parseEther("1");
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const Arbitrage = await ethers.getContractFactory("Arbitrage");
    const arbitrageContract = await Arbitrage.deploy(WETH);
    await arbitrageContract.deployed();
    console.log({ "Arbitrage Contract Adddress": arbitrageContract.address })
    return { Arbitrage, arbitrageContract };

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
