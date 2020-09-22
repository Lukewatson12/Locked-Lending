import {Signer} from "ethers";
import {deployContract, MockProvider} from "ethereum-waffle";
import {oneEther} from "./numbers";

import LiquidityPoolErc20Artifact from "../../artifacts/LiquidityPoolErc20.json";
import WrappedLiquidityPoolTokenArtifact from "../../artifacts/WrappedLiquidityPoolToken.json";
import FairTokenArtifact from "../../artifacts/FairToken.json";

import {FairToken} from "../../typechain/FairToken";
import {LiquidityPoolErc20} from "../../typechain/LiquidityPoolErc20";
import {WrappedLiquidityPoolToken} from "../../typechain/WrappedLiquidityPoolToken";

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

export async function deployLiquidityPoolErc20(signer: Signer) {
  return (await deployContract(signer, LiquidityPoolErc20Artifact, [
    "LIQUIDITY POOL",
    "LEND",
  ])) as LiquidityPoolErc20;
}

export async function deployWrappedLiquidityPoolToken(
  signer: Signer,
  token: LiquidityPoolErc20
) {
  const wrappedLiquidityPoolToken = (await deployContract(
    signer,
    WrappedLiquidityPoolTokenArtifact,
    [token.address]
  )) as WrappedLiquidityPoolToken;

  await signer
    .getAddress()
    .then((address) => token.mint(address, oneEther.mul(500)));

  await token.approve(wrappedLiquidityPoolToken.address, oneEther.mul(500));

  return wrappedLiquidityPoolToken;
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
