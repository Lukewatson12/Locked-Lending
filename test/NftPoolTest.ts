import chai from "chai";
import {BigNumber} from "ethers";
import {
  deployLiquidityPoolErc20,
  deployWrappedLiquidityPoolToken,
  getBlockTime,
  getProvider,
  wait,
} from "./helpers/contract";
import {deployContract} from "ethereum-waffle";

import FairTokenArtifact from "../artifacts/FairToken.json";
import NftPoolArtifact from "../artifacts/NftPool.json";

import {NftPool} from "../typechain/NftPool";
import {FairToken} from "../typechain/FairToken";
import {WrappedLiquidityPoolToken} from "../typechain/WrappedLiquidityPoolToken";
import {LiquidityPoolErc20} from "../typechain/LiquidityPoolErc20";

import {oneHour} from "./helpers/numbers";

const {expect} = chai;

const [deployer, alice] = getProvider().getWallets();

describe("Locked Liquidity Pool Token", () => {
  const oneEther = BigNumber.from(10).pow(18);

  let wrappedLiquidityPoolToken: WrappedLiquidityPoolToken;
  let liquidityPoolToken: LiquidityPoolErc20;
  let token: FairToken;
  let pool: NftPool;
  let alicePool: NftPool;

  let timestamp: number;
  let amount = oneEther.mul(100);

  beforeEach(async () => {
    token = (await deployContract(deployer, FairTokenArtifact)) as FairToken;
    liquidityPoolToken = await deployLiquidityPoolErc20(alice);
    timestamp = await getBlockTime();

    wrappedLiquidityPoolToken = await deployWrappedLiquidityPoolToken(
      alice,
      liquidityPoolToken
    );

    pool = (await deployContract(deployer, NftPoolArtifact)) as NftPool;

    await pool.setWrappedLiquidityPoolToken(wrappedLiquidityPoolToken.address);
    await pool.setToken(token.address);

    await token.addMinter(pool.address);

    await pool.setRewardDistribution(deployer.address);
    await pool.notifyRewardAmount(oneEther.mul(10000));

    alicePool = await pool.connect(alice);
  });

  it("Should calculate the amount of liquidity value given different lock periods ", async () => {
    await pool.calculateLiquidityValue(1, 1000).then((lockValue) => {
      expect(lockValue).to.eq(10000);
    });
    await pool.calculateLiquidityValue(2, 1000).then((lockValue) => {
      expect(lockValue).to.eq(25000);
    });
    await pool.calculateLiquidityValue(3, 1000).then((lockValue) => {
      expect(lockValue).to.eq(75000);
    });
  });

  it("Should allow a token to be staked and update views to reflect", async () => {
    await setupLiquidityPoolLock();

    await pool.totalStake().then((totalStaked: BigNumber) => {
      expect(totalStaked).to.eq(0);
    });

    await pool.liquidityTokens(alice.address).then((aliceTokens : BigNumber) => {
      expect(aliceTokens).to.eq(0);
    });

    await alicePool.stake(1);

    await pool.totalStake().then((totalStaked: BigNumber) => {
      expect(totalStaked).to.eq(amount);
    });

    await pool.liquidityTokens(alice.address).then((aliceTokens: BigNumber) => {
      expect(aliceTokens).to.eq(amount);
    });
  });

  it("Should calculate the reward based on the total amount & duration", async () => {
    await setupLiquidityPoolLock();
    await alicePool.stake(1);
  });

  async function setupLiquidityPoolLock() {
    await wrappedLiquidityPoolToken.lockLiquidityPoolToken(amount, 1);
    await wrappedLiquidityPoolToken.approve(pool.address, 1);
  }
});
