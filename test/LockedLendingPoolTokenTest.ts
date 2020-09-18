import chai from "chai";
import {LockedLendingPoolToken} from "../typechain/LockedLendingPoolToken";
import {MockErc20} from "../typechain/MockErc20";
import {BigNumber} from "ethers";
import {deployErc20, deployLockedLendingPoolToken, getBlockTime, getProvider} from "./helpers/contract";
import {oneHour} from "./helpers/numbers";

const {expect} = chai;

const [alice, bob] = getProvider().getWallets();

describe("Locked Lending Pool Token", () => {
    const oneEther = BigNumber.from(10).pow(18);

    let lockedLendingPoolToken: LockedLendingPoolToken;
    let token: MockErc20;
    let timestamp: number;

    beforeEach(async () => {
        token = await deployErc20(alice);
        timestamp = await getBlockTime();

        lockedLendingPoolToken = await deployLockedLendingPoolToken(alice);

        await token.mint(alice.address, oneEther.mul(500));
        await token.approve(lockedLendingPoolToken.address, oneEther.mul(500));
    });

    it("Should mint a Locked Lending Pool Token", async () => {
        let amount = oneEther.mul(100);

        await lockedLendingPoolToken.lockLendingPoolToken(
            token.address,
            amount,
            oneHour
        );

        await lockedLendingPoolToken.getTokenById(1).then((llpToken: any) => {
            expect(llpToken.amount).to.eq(amount);
            expect(llpToken.lockStart.toNumber()).to.be.approximately(timestamp, 10);
            expect(llpToken.lockEnd.toNumber()).to.be.approximately(timestamp + oneHour, 10);
            expect(llpToken.isEntity).to.be.true;
        });
    });

    it("Should transfer the LP tokens into the Lock contract", async () => {
        let amount = oneEther.mul(100);

        await lockedLendingPoolToken.lockLendingPoolToken(
            token.address,
            amount,
            oneHour
        );

        await token.balanceOf(lockedLendingPoolToken.address).then(balance => {
            expect(balance).to.eq(amount)
        });

        await token.balanceOf(alice.address).then(balance => {
            expect(balance).to.eq(oneEther.mul(400))
        });
    });
});
