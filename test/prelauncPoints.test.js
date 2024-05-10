const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("MonadexPrelaunchPoints", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployPrelaunchPointsFixture() {
        const [owner, user0, user1, user2] = await ethers.getSigners();

        const PrelauncPoints = await ethers.getContractFactory(
            "MonadexPrelaunchPoints",
        );
        const prelauncPoints = await PrelauncPoints.deploy();

        return { prelauncPoints, owner, user0, user1, user2 };
    }
});
