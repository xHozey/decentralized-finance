import { HardhatEthers } from "@nomicfoundation/hardhat-ethers/types";
import { network } from "hardhat";

async function main() {
  const ethers = (await network.connect()).ethers;
  const [deployer, secondUser] = await ethers.getSigners();
  const Oracle = await ethers.getContractFactory("Oracle");
  const oracle = await Oracle.deploy();
  await oracle.setPrice(1000);
  console.log("price: ", await oracle.getPrice());
  const { stable, volatile, lstable, lvolatile } = await deployTokens(ethers);

  const LendingPlatform = await ethers.getContractFactory("LendingPlatform");
  const lendingPlatform = await LendingPlatform.deploy(
    volatile.getAddress(),
    stable.getAddress(),
    lstable.getAddress(),
    lvolatile.getAddress()
  );
  await lendingPlatform.registerOracle(oracle);
  await stable.approve(lendingPlatform.target, 200);
  await lendingPlatform.depositStable(200);
  console.log(
    "lstable balance: ",
    await lstable.balanceOf(await deployer.getAddress())
  );
  await volatile.transfer(await secondUser.getAddress(), 2000);
  await volatile.connect(secondUser).approve(lendingPlatform.target, 2000);
  await lendingPlatform.connect(secondUser).depositVolatile(2000);
  console.log(
    "lvolatile balance: ",
    await lvolatile.balanceOf(secondUser.getAddress())
  );

  try {
    await lendingPlatform.borrowStable(200);
  } catch (e) {
    console.log("borrow failed");
  }

  try {
    await lendingPlatform.borrowStable(20);
    console.log(
      "borrow success, stable balance: ",
      await stable.balanceOf(await deployer.getAddress())
    );
  } catch (e) {
    console.log("borrow failed");
  }
}

async function deployTokens(ethers: HardhatEthers) {
  const Lstable = await ethers.getContractFactory("LStable");
  const lstable = await Lstable.deploy();

  const Lvolatile = await ethers.getContractFactory("Lvolatile");
  const lvolatile = await Lvolatile.deploy();

  const Stable = await ethers.getContractFactory("Stable");
  const stable = await Stable.deploy();

  const Volatile = await ethers.getContractFactory("Volatile");
  const volatile = await Volatile.deploy();

  return { stable, volatile, lstable, lvolatile };
}

main();
