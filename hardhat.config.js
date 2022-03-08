require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    rinkby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/PwcUFve-d1F-pSlzNK4qjdJodGQeFR1G`,
      accounts: ["a1ff6559167296eda10a3dc0484e2680ed1bb7fb09b7ebb9a1f97c2bc28701d9"],
    }
  }
};
