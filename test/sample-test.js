const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const NFTContract = await ethers.getContractFactory("NFTContract");
    const nft = await NFTContract.deploy("ABCDEF");
    await nft.deployed();    

    const setGreetingTx = await nft.setWhitelistMerkleRoot("0x3b76d7876dd42d8885cbd878e84065b8ea09ec27a5e7225824585ebf78c54816");
    await setGreetingTx.wait();
    const amount = "0.0002"; // Willing to send 2 ethers
    const amountToSend = ethers.toWei(amount, "ether"); // Convert to wei value
    const presale = await nft.preSale(2, ["0x581c94df17296216fdfadd9dafc3b78b8fff433a3c9883c51609d23b35cf023a", "0x581c94df17296216fdfadd9dafc3b78b8fff433a3c9883c51609d23b35cf023a"],{price: amountToSend});
    await presale.wait();
  });
});
