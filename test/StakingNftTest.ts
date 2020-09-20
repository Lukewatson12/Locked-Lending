import chai from "chai";
import {LockedLendingPoolNft} from "../typechain/LockedLendingPoolNft";
import {MintableErc20} from "../typechain/MintableErc20";
import {BigNumber} from "ethers";
import {
  deployErc20,
  deployLockedLendingPoolToken,
  getBlockTime,
  getProvider,
} from "./helpers/contract";
import {deployContract} from "ethereum-waffle";
import LockedLendingErc20PoolArtifact from "../artifacts/LockedLendingErc20Pool.json";
import {LockedLendingErc20Pool} from "../typechain/LockedLendingErc20Pool";
import FairArtifact from "../artifacts/FAIR.json";
import {Fair} from "../typechain/Fair";
import {oneHour} from "./helpers/numbers";

const {expect} = chai;

const [deployer, alice] = getProvider().getWallets();

describe("Locked Lending Pool Token", () => {
  const oneEther = BigNumber.from(10).pow(18);

  let lockedLendingPoolNft: LockedLendingPoolNft;
  let lendingPoolToken: MintableErc20;
  let token: Fair;
  let pool: LockedLendingErc20Pool;
  let timestamp: number;
  let amount = oneEther.mul(100);

  beforeEach(async () => {
    token = (await deployContract(deployer, FairArtifact)) as Fair;
    lendingPoolToken = await deployErc20(alice);
    timestamp = await getBlockTime();

    lockedLendingPoolNft = await deployLockedLendingPoolToken(
      alice,
      lendingPoolToken
    );

    pool = (await deployContract(
      deployer,
      LockedLendingErc20PoolArtifact
    )) as LockedLendingErc20Pool;

    await token.addMinter(pool.address);

    await pool.setRewardDistribution(deployer.address);
    await pool.notifyRewardAmount(oneEther.mul(10000));
  });

  it("Should accept a Locked Lending pool token and calculate the reward based on the total amount & duration", async () => {
    await setupLendingPoolLock();
    await pool.stake(1);
  });

  async function setupLendingPoolLock() {
    await lockedLendingPoolNft.lockLendingPoolToken(amount, oneHour);
  }
});
