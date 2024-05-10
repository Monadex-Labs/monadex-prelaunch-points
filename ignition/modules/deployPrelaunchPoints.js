const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MonadexPrelaunchPointsModule", (m) => {
    const prelauncPoints = m.contract("MonadexPrelaunchPoints");

    return { prelauncPoints };
});
