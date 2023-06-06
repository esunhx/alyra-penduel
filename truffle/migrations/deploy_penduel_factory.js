require('dotenv').config();

const PenduelFactory = artifacts.require("PenduelFactory");
const MockLinkToken = artifacts.require("LinkToken");
const VRFCoordinatorV2Mock = artifacts.require("VRFCoordinatorV2Mock");
const MockV3Aggregator = artifacts.require("MockV3Aggregator");

const deployMocks = (deployer) => {
    return Promise.all([
        deployer.deploy(
            MockLinkToken
        ),
        deployer.deploy(
            VRFCoordinatorV2Mock,
            100000,
            100000
        ),
        deployer.deploy(
            MockV3Aggregator,
            18,
            207810000000
        )
    ])
}

module.exports = async function (deployer) {
    let vrfCoordinatorAddress, linkToken, vrfKeyHash, vrfSubscriptionId, 
    callBackGasLimit, requestsConfirmation;

    if (config.network === "development") {
        await deployMocks(deployer);

        vrfCoordinatorAddress = VRFCoordinatorV2Mock.address;
        linkToken = MockLinkToken.address;
        vrfKeyHash = "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc";
        vrfSubscriptionId = 1;
        callBackGasLimit = 30000;
        requestsConfirmation = 1;
        // priceFeedAddress = MockV3Aggregator.address;
    } else {
        // vrfCoordinatorAddress = process.env.VRF_COORDINATOR_ADDRESS;
        // vrfKeyHash = process.env.VRF_KEY_HASH;
        // vrfSubscriptionId = process.env.VRF_SUBSCRIPTION_ID;
        // priceFeedAddress = process.env.V3_AGGREGATOR;
    }

    await deployer.deploy(
        PenduelFactory,
        vrfCoordinatorAddress,
        linkToken,
        vrfKeyHash,
        vrfSubscriptionId,
        callBackGasLimit,
        requestsConfirmation
    )
}