import {Signer} from "ethers";
import {deployContract, MockProvider} from "ethereum-waffle";
import {MockErc20} from "../../typechain/MockErc20";
import MintableErc20Artifact from "../../artifacts/MintableErc20.json";
import LockedLendingPoolNftArtifact from "../../artifacts/LockedLendingPoolNft.json";
import {LockedLendingPoolToken} from "../../typechain/LockedLendingPoolToken";
import {MintableErc20} from "../../typechain/MintableErc20";

let provider: MockProvider;

export function getProvider() {
  if (provider == undefined) {
    provider = new MockProvider();
  }
  return provider;
}

export async function deployErc20(signer: Signer) {
  return (await deployContract(signer, MintableErc20Artifact, [
    "LENDING POOL",
    "LEND",
  ])) as MintableErc20;
}

export async function deployLockedLendingPoolToken(
  signer: Signer,
  token: MockErc20
) {
  return (await deployContract(signer, LockedLendingPoolNftArtifact, [
    token.address,
  ])) as LockedLendingPoolToken;
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
