// scripts/exercise1.js
import { network } from "hardhat";

async function main() {
  const { ethers } = await network.connect();
  const [deployer, anotherUser] = await ethers.getSigners();
  const Oracle = await ethers.getContractFactory("Oracle");
  const oracle = await Oracle.deploy();
  await oracle.setEthPrice(1000);
  console.log(`ETH Price from Oracle: ${await oracle.getEthPrice()}`);

  const oracleAddress = await oracle.getAddress();
  const StableCoin = await ethers.getContractFactory("StableCoin");
  const stableCoin = await StableCoin.deploy();
  await stableCoin.registerOracle(oracleAddress);
  console.log(await stableCoin.oracle());

  await stableCoin.deposit({ value: ethers.parseEther("1") });
  console.log(
    "Deposit (ETH):",
    ethers.formatEther(await stableCoin.collateralETH(deployer.address))
  );

  await stableCoin.mint(200);
  console.log(
    "Minted StableCoin:",
    await stableCoin.balanceOf(deployer.address)
  );

  try {
    await stableCoin.mint(3000);
  } catch (err) {
    console.log(err.message);
  }

  try {
    await stableCoin.withdraw(ethers.parseEther("1"))
  } catch(e) {
    console.log(e.message)
  }

  await stableCoin.burn(200);
  console.log(
    "StableCoin after burn:",
    await stableCoin.balanceOf(deployer.address)
  );
  await stableCoin.deposit({ value: ethers.parseEther("1") });
  await stableCoin.mint(500);
  await stableCoin
    .connect(anotherUser)
    .deposit({ value: ethers.parseEther("1") });
  await stableCoin.connect(anotherUser).mint(500);
  await oracle.setEthPrice(1);
  try {
    await stableCoin.connect(anotherUser).liquidate(deployer.address);
    console.log("Liquidation successful");
  } catch (e) {
    console.log("failed to liquidate:", e.message);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
