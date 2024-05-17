const { ethers, upgrades } = require("hardhat");

async function upgradeMonadexPrelaunchPoints() {
    const [owner] = await ethers.getSigners();
    const MonadexPrelaunchPointsFactory = await ethers.getContractFactory(
        "MonadexPrelaunchPoints",
    );
    // Add the address of the old implementation here
    const MONADEX_PRELAUNCH_POINTS_ADDRESS = "0x";

    console.log("Upgrading `MonadexPrelaunchPoints`...");

    const monadexPrelaunchPoints = await upgrades.upgradeProxy(
        MONADEX_PRELAUNCH_POINTS_ADDRESS,
        MonadexPrelaunchPointsFactory,
    );

    console.log("MonadexPrelaunchPoints upgraded successfully");

    return { monadexPrelaunchPoints };
}

upgradeMonadexPrelaunchPoints().catch((error) => console.log(error));
