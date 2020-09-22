import chai from "chai";
import {WrappedLiquidityPoolToken} from "../typechain/WrappedLiquidityPoolToken";
import {BigNumber} from "ethers";
import {
  deployLiquidityPoolErc20,
  deployWrappedLiquidityPoolToken,
  getBlockTime,
  getProvider,
  wait,
} from "./helpers/contract";
import {oneHour, oneMonth} from "./helpers/numbers";
import {LiquidityPoolErc20} from "../typechain/LiquidityPoolErc20";

const {expect} = chai;

const [alice, bob] = getProvider().getWallets();

describe("Locked Liquidity Pool Token", () => {
  const oneEther = BigNumber.from(10).pow(18);

  let lockedLiquidityPoolNft: WrappedLiquidityPoolToken;
  let liquidityPoolErc20: LiquidityPoolErc20;
  let timestamp: number;
  let amount = oneEther.mul(100);

  beforeEach(async () => {
    timestamp = await getBlockTime();

    liquidityPoolErc20 = await deployLiquidityPoolErc20(alice);
    lockedLiquidityPoolNft = await deployWrappedLiquidityPoolToken(
      alice,
      liquidityPoolErc20
    );
  });

  it("Should mint a Locked Liquidity Pool Token", async () => {
    await setupLiquidityPoolLock();

    await lockedLiquidityPoolNft.getTokenById(1).then((llpToken: any) => {
      expect(llpToken.amount).to.eq(amount);
      expect(llpToken.lockStart.toNumber()).to.be.approximately(timestamp, 10);
      expect(llpToken.lockEnd.toNumber()).to.be.approximately(
        timestamp + oneMonth,
        10
      );
      expect(llpToken.isEntity).to.be.true;
      expect(llpToken.lockPeriod).to.be.eq(1);
    });
  });

  it("Should transfer the LP tokens into the Lock contract", async () => {
    await setupLiquidityPoolLock();

    await liquidityPoolErc20
      .balanceOf(lockedLiquidityPoolNft.address)
      .then((balance) => {
        expect(balance).to.eq(amount);
      });

    await liquidityPoolErc20.balanceOf(alice.address).then((balance) => {
      expect(balance).to.eq(oneEther.mul(400));
    });
  });

  it("Should prevent withdrawal if the lock period has not been elapsed", async () => {
    await setupLiquidityPoolLock();

    await expect(lockedLiquidityPoolNft.withdraw(1)).to.be.revertedWith(
      "Tokens are still locked"
    );
  });

  it("Should allow withdrawal if the lock period has been elapsed", async () => {
    await setupLiquidityPoolLock();

    await wait(oneMonth);

    await lockedLiquidityPoolNft.withdraw(1);

    await liquidityPoolErc20
      .balanceOf(lockedLiquidityPoolNft.address)
      .then((balance) => {
        expect(balance).to.eq(0);
      });

    await liquidityPoolErc20.balanceOf(alice.address).then((balance) => {
      expect(balance).to.eq(oneEther.mul(500));
    });
  });

  it("Should burn the liquidityPoolErc20 after withdrawal", async () => {
    await setupLiquidityPoolLock();

    await wait(oneMonth);

    await lockedLiquidityPoolNft.withdraw(1);

    await lockedLiquidityPoolNft.getTokenById(1).then((llpToken: any) => {
      expect(llpToken.amount).to.eq(0);
      expect(llpToken.lockStart.toNumber()).to.be.eq(0);
      expect(llpToken.lockEnd.toNumber()).to.be.eq(0);
      expect(llpToken.isEntity).to.be.false;
    });

    await expect(lockedLiquidityPoolNft.ownerOf(1)).to.be.revertedWith(
      "ERC721: owner query for nonexistent token"
    );
  });

  it("Should disallow creation of a lock with FINISHED lock period set", async () => {
    await expect(
      lockedLiquidityPoolNft.lockLiquidityPoolToken(amount, 0)
    ).to.be.revertedWith("Must set a valid lock period");
  });

  it("Should only allow for valid lock periods", async () => {
    await expect(lockedLiquidityPoolNft.lockLiquidityPoolToken(amount, 420)).to.be
      .reverted;
  });

  async function setupLiquidityPoolLock() {
    await lockedLiquidityPoolNft.lockLiquidityPoolToken(amount, 1);
  }
});
