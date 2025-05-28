import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const fakeUSDC = await deploy("FakeUSDC", { from: deployer, log: true, autoMine: true });

  const creator = "0xA9bC8A58B39935BA3D8D1Ce4b0d3383153F184E1";
  const startTime = 1748457700;
  const endTime = 1751136100;
  const moneyGoal = 100000000;

  await deploy("Crowdfunding", {
    from: deployer,
    // Contract constructor arguments
    args: [creator, startTime, endTime, moneyGoal, fakeUSDC.address],
    log: true,
    autoMine: true,
  });
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["Crowdfunding"];
