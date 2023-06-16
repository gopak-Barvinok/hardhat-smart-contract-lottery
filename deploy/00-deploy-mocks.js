const { developmentChains } = require("../helper-hardhat-config");


const BASE_FEE = ethers.utils.parseEther("0.25")
const GAS_PIRCE_LINK = 1e9;

module.exports = async function({getNamedAccounts, deployments}){
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const args = [BASE_FEE, GAS_PIRCE_LINK];

    if(developmentChains.includes(network.name)) {
        log("Local network detected! Deploying mocks...")
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: args
        })
        log("Mocks deployed!")
        log("---------------------------------------------------------------------------------------------")

    }
}

module.exports.tags = ["all", "mocks"]