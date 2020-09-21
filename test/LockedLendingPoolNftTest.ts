import chai from "chai";
import {WrappedLendingPoolToken} from "../typechain/WrappedLendingPoolToken";
import {BigNumber} from "ethers";
import {
  deployLendingPoolErc20,
  deployWrappedLendingPoolToken,
  getBlockTime,
  getProvider,
  wait,
} from "./helpers/contract";
import {oneHour, oneMonth} from "./helpers/numbers";
import {LendingPoolErc20} from "../typechain/LendingPoolErc20";

const {expect} = chai;

const [alice, bob] = getProvider().getWallets();

describe("Locked Lending Pool Token", () => {
  const oneEther = BigNumber.from(10).pow(18);

  let lockedLendingPoolNft: WrappedLendingPoolToken;
  let lendingPoolErc20: LendingPoolErc20;
  let timestamp: number;
  let amount = oneEther.mul(100);

  beforeEach(async () => {
    timestamp = await getBlockTime();

    lendingPoolErc20 = await deployLendingPoolErc20(alice);
    lockedLendingPoolNft = await deployWrappedLendingPoolToken(
      alice,
      lendingPoolErc20
    );
  });

  it("Should mint a Locked Lending Pool Token", async () => {
    await setupLendingPoolLock();

    await lockedLendingPoolNft.getTokenById(1).then((llpToken: any) => {
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
    await setupLendingPoolLock();

    await lendingPoolErc20
      .balanceOf(lockedLendingPoolNft.address)
      .then((balance) => {
        expect(balance).to.eq(amount);
      });

    await lendingPoolErc20.balanceOf(alice.address).then((balance) => {
      expect(balance).to.eq(oneEther.mul(400));
    });
  });

  it("Should prevent withdrawal if the lock period has not been elapsed", async () => {
    await setupLendingPoolLock();

    await expect(lockedLendingPoolNft.withdraw(1)).to.be.revertedWith(
      "Tokens are still locked"
    );
  });

  it("Should allow withdrawal if the lock period has been elapsed", async () => {
    await setupLendingPoolLock();

    await wait(oneMonth);

    await lockedLendingPoolNft.withdraw(1);

    await lendingPoolErc20
      .balanceOf(lockedLendingPoolNft.address)
      .then((balance) => {
        expect(balance).to.eq(0);
      });

    await lendingPoolErc20.balanceOf(alice.address).then((balance) => {
      expect(balance).to.eq(oneEther.mul(500));
    });
  });

  it("Should burn the lendingPoolErc20 after withdrawal", async () => {
    await setupLendingPoolLock();

    await wait(oneMonth);

    await lockedLendingPoolNft.withdraw(1);

    await lockedLendingPoolNft.getTokenById(1).then((llpToken: any) => {
      expect(llpToken.amount).to.eq(0);
      expect(llpToken.lockStart.toNumber()).to.be.eq(0);
      expect(llpToken.lockEnd.toNumber()).to.be.eq(0);
      expect(llpToken.isEntity).to.be.false;
    });

    await expect(lockedLendingPoolNft.ownerOf(1)).to.be.revertedWith(
      "ERC721: owner query for nonexistent token"
    );
  });

  it("Should disallow creation of a lock with FINISHED lock period set", async () => {
    await expect(
      lockedLendingPoolNft.lockLendingPoolToken(amount, 0)
    ).to.be.revertedWith("Must set a valid lock period");
  });

  it("Should only allow for valid lock periods", async () => {
    await expect(lockedLendingPoolNft.lockLendingPoolToken(amount, 420)).to.be
      .reverted;
  });

  async function setupLendingPoolLock() {
    await lockedLendingPoolNft.lockLendingPoolToken(amount, 1);
  }
});
