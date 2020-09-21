import {Signer} from "ethers";
import {deployContract, MockProvider} from "ethereum-waffle";
import {oneEther} from "./numbers";

import LendingPoolErc20Artifact from "../../artifacts/LendingPoolErc20.json";
import WrappedLendingPoolTokenArtifact from "../../artifacts/WrappedLendingPoolToken.json";
import FairTokenArtifact from "../../artifacts/FairToken.json";

import {FairToken} from "../../typechain/FairToken";
import {LendingPoolErc20} from "../../typechain/LendingPoolErc20";
import {WrappedLendingPoolToken} from "../../typechain/WrappedLendingPoolToken";

let provider: MockProvider;

export function getProvider() {
  if (provider == undefined) {
    provider = new MockProvider();
  }
  return provider;
}

export async function deployFairToken(signer: Signer) {
  return (await deployContract(signer, FairTokenArtifact)) as FairToken;
}

export async function deployLendingPoolErc20(signer: Signer) {
  return (await deployContract(signer, LendingPoolErc20Artifact, [
    "LENDING POOL",
    "LEND",
  ])) as LendingPoolErc20;
}

export async function deployWrappedLendingPoolToken(
  signer: Signer,
  token: LendingPoolErc20
) {
  const wrappedLendingPoolToken = (await deployContract(signer, WrappedLendingPoolTokenArtifact, [
    token.address,
  ])) as WrappedLendingPoolToken;

  await signer
    .getAddress()
    .then((address) => token.mint(address, oneEther.mul(500)));

  await token.approve(wrappedLendingPoolToken.address, oneEther.mul(500));

  return wrappedLendingPoolToken;
}

export async function wait(amountOfTimeToWait: number) {
  // Update the clock
  await getProvider().send("evm_increaseTime", [amountOfTimeToWait]);

  // Process the block
  await getProvider().send("evm_mine", []);
}

// Get time and add 1 to prevent timestamp issues
export async function getBlockTime() {
  return await getProvider()
    .getBlock(getBlockNumber())
    .then((block) => block.timestamp);
}

export async function getBlockNumber() {
  return await getProvider().getBlockNumber();
}
