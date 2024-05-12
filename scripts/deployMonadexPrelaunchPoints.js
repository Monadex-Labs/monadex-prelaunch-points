const { ethers, upgrades } = require("hardhat");

async function deployMonadexPrelaunchPoints() {
    const [owner] = await ethers.getSigners();
    const MonadexPrelaunchPointsFactory = await ethers.getContractFactory(
        "MonadexPrelaunchPoints",
    );

    console.log("Deploying `MonadexPrelaunchPoints`...");

    const monadexPrelaunchPoints = await upgrades.deployProxy(
        MonadexPrelaunchPointsFactory,
        [owner.address],
        {
            initializer: "initialize",
        },
    );
    await monadexPrelaunchPoints.waitForDeployment();

    console.log(
        `MonadexPrelaunchPoints deployed at: ${await monadexPrelaunchPoints.getAddress()}`,
    );

    return { monadexPrelaunchPoints };
}

deployMonadexPrelaunchPoints().catch((error) => console.log(error));
