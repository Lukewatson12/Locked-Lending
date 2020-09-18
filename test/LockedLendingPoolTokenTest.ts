import chai from "chai";
import {LockedLendingPoolToken} from "../typechain/LockedLendingPoolToken";
import {MockErc20} from "../typechain/MockErc20";
import {BigNumber} from "ethers";
import {deployErc20, deployLockedLendingPoolToken, getBlockTime, getProvider, wait} from "./helpers/contract";
import {oneHour} from "./helpers/numbers";

const {expect} = chai;

const [alice, bob] = getProvider().getWallets();

describe("Locked Lending Pool Token", () => {
    const oneEther = BigNumber.from(10).pow(18);

    let lockedLendingPoolToken: LockedLendingPoolToken;
    let token: MockErc20;
    let timestamp: number;
    let amount = oneEther.mul(100);

    beforeEach(async () => {
        token = await deployErc20(alice);
        timestamp = await getBlockTime();

        lockedLendingPoolToken = await deployLockedLendingPoolToken(alice, token);

        await token.mint(alice.address, oneEther.mul(500));
        await token.approve(lockedLendingPoolToken.address, oneEther.mul(500));
    });

    it("Should mint a Locked Lending Pool Token", async () => {
        await setupLendingPoolLock();

        await lockedLendingPoolToken.getTokenById(1).then((llpToken: any) => {
            expect(llpToken.amount).to.eq(amount);
            expect(llpToken.lockStart.toNumber()).to.be.approximately(timestamp, 10);
            expect(llpToken.lockEnd.toNumber()).to.be.approximately(timestamp + oneHour, 10);
            expect(llpToken.isEntity).to.be.true;
        });
    });

    it("Should transfer the LP tokens into the Lock contract", async () => {
        await setupLendingPoolLock();

        await token.balanceOf(lockedLendingPoolToken.address).then(balance => {
            expect(balance).to.eq(amount)
        });

        await token.balanceOf(alice.address).then(balance => {
            expect(balance).to.eq(oneEther.mul(400))
        });
    });

    it("Should prevent withdrawal if the lock period has not been elapsed", async () => {
        await setupLendingPoolLock();

        await expect(lockedLendingPoolToken.withdraw(1)).to.be.revertedWith("Tokens are still locked");
    });

    it("Should allow withdrawal if the lock period has been elapsed", async () => {
        await setupLendingPoolLock();

        await wait(oneHour);

        await lockedLendingPoolToken.withdraw(1);
    });

    async function setupLendingPoolLock() {
        await lockedLendingPoolToken.lockLendingPoolToken(
            amount,
            oneHour
        );
    }
});
