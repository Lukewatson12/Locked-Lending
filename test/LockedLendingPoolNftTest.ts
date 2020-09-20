import chai from "chai";
import {LockedLendingPoolNft} from "../typechain/LockedLendingPoolNft";
import {MintableErc20} from "../typechain/MintableErc20";
import {BigNumber} from "ethers";
import {
  deployErc20,
  deployLockedLendingPoolToken,
  getBlockTime,
  getProvider,
  wait,
} from "./helpers/contract";
import {oneHour} from "./helpers/numbers";

const {expect} = chai;

const [alice, bob] = getProvider().getWallets();

describe("Locked Lending Pool Token", () => {
  const oneEther = BigNumber.from(10).pow(18);

  let lockedLendingPoolNft: LockedLendingPoolNft;
  let token: MintableErc20;
  let timestamp: number;
  let amount = oneEther.mul(100);

  beforeEach(async () => {
    token = await deployErc20(alice);
    timestamp = await getBlockTime();

    lockedLendingPoolNft = await deployLockedLendingPoolToken(alice, token);
  });

  it("Should mint a Locked Lending Pool Token", async () => {
    await setupLendingPoolLock();

    await lockedLendingPoolNft.getTokenById(1).then((llpToken: any) => {
      expect(llpToken.amount).to.eq(amount);
      expect(llpToken.lockStart.toNumber()).to.be.approximately(timestamp, 10);
      expect(llpToken.lockEnd.toNumber()).to.be.approximately(
        timestamp + oneHour,
        10
      );
      expect(llpToken.isEntity).to.be.true;
    });
  });

  it("Should transfer the LP tokens into the Lock contract", async () => {
    await setupLendingPoolLock();

    await token.balanceOf(lockedLendingPoolNft.address).then((balance) => {
      expect(balance).to.eq(amount);
    });

    await token.balanceOf(alice.address).then((balance) => {
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

    await wait(oneHour);

    await lockedLendingPoolNft.withdraw(1);

    await token.balanceOf(lockedLendingPoolNft.address).then((balance) => {
      expect(balance).to.eq(0);
    });

    await token.balanceOf(alice.address).then((balance) => {
      expect(balance).to.eq(oneEther.mul(500));
    });
  });

  it("Should burn the token after withdrawal", async () => {
    await setupLendingPoolLock();

    await wait(oneHour);

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

  async function setupLendingPoolLock() {
    await lockedLendingPoolNft.lockLendingPoolToken(amount, oneHour);
  }
});
