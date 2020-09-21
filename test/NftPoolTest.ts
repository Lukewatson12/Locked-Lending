import chai from "chai";
import {BigNumber} from "ethers";
import {
  deployLendingPoolErc20,
  deployWrappedLendingPoolToken,
  getBlockTime,
  getProvider,
  wait,
} from "./helpers/contract";
import {deployContract} from "ethereum-waffle";

import FairTokenArtifact from "../artifacts/FairToken.json";
import NftPoolArtifact from "../artifacts/NftPool.json";

import {NftPool} from "../typechain/NftPool";
import {FairToken} from "../typechain/FairToken";
import {WrappedLendingPoolToken} from "../typechain/WrappedLendingPoolToken";
import {LendingPoolErc20} from "../typechain/LendingPoolErc20";

import {oneHour} from "./helpers/numbers";

const {expect} = chai;

const [deployer, alice] = getProvider().getWallets();

describe("Locked Lending Pool Token", () => {
  const oneEther = BigNumber.from(10).pow(18);

  let wrappedLendingPoolToken: WrappedLendingPoolToken;
  let lendingPoolToken: LendingPoolErc20;
  let token: FairToken;
  let pool: NftPool;
  let alicePool: NftPool;

  let timestamp: number;
  let amount = oneEther.mul(100);

  beforeEach(async () => {
    token = (await deployContract(deployer, FairTokenArtifact)) as FairToken;
    lendingPoolToken = await deployLendingPoolErc20(alice);
    timestamp = await getBlockTime();

    wrappedLendingPoolToken = await deployWrappedLendingPoolToken(
      alice,
      lendingPoolToken
    );

    pool = (await deployContract(deployer, NftPoolArtifact)) as NftPool;

    await pool.setWrappedLendingPoolToken(wrappedLendingPoolToken.address);
    await pool.setToken(token.address);

    await token.addMinter(pool.address);

    await pool.setRewardDistribution(deployer.address);
    await pool.notifyRewardAmount(oneEther.mul(10000));

    alicePool = await pool.connect(alice);
  });

  it("Should calculate the amount of lending value given different lock periods ", async () => {
    await pool.calculateLendingValue(1, 1000).then((lockValue) => {
      expect(lockValue).to.eq(10000);
    });
    await pool.calculateLendingValue(2, 1000).then((lockValue) => {
      expect(lockValue).to.eq(25000);
    });
    await pool.calculateLendingValue(3, 1000).then((lockValue) => {
      expect(lockValue).to.eq(75000);
    });
  });

  it("Should allow a token to be staked and update views to reflect", async () => {
    await setupLendingPoolLock();

    await alicePool.stake(1);
    await pool.totalStaked().then((totalStaked) => {
      expect(totalStaked).to.eq(amount);
    });

    await pool.balanceOf(alice.address).then((aliceStake) => {
      expect(aliceStake).to.eq(amount);
    });
  });

  it("Should calculate the reward based on the total amount & duration", async () => {
    await setupLendingPoolLock();
    await alicePool.stake(1);
  });

  async function setupLendingPoolLock() {
    await wrappedLendingPoolToken.lockLendingPoolToken(amount, 1);
    await wrappedLendingPoolToken.approve(pool.address, 1);
  }
});
