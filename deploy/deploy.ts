/* eslint-disable */

const chainName = (chainId: any) => {
    switch (chainId) {
        case 1:
            return 'Mainnet';
        case 3:
            return 'Ropsten';
        case 4:
            return 'Rinkeby';
        case 5:
            return 'Goerli';
        case 42:
            return 'Kovan';
        case 56:
            return 'Binance Smart Chain';
        case 77:
            return 'POA Sokol';
        case 97:
            return 'Binance Smart Chain (testnet)';
        case 99:
            return 'POA';
        case 100:
            return 'xDai';
        case 137:
            return 'Matic';
        case 31337:
            return 'HardhatEVM';
        case 80001:
            return 'Matic (Mumbai)';
        default:
            return 'Unknown';
    }
};

module.exports = async (hardhat: any) => {
    const { getNamedAccounts, deployments, getChainId, ethers } = hardhat;
    const { deploy } = deployments;

    let { deployer } = await getNamedAccounts();
    const chainId = parseInt(await getChainId(), 10);

    // 31337 is unit testing, 1337 is for coverage
    const isTestEnvironment = chainId === 31337 || chainId === 1337;

    const signer = await ethers.provider.getSigner(deployer);


    console.log(`Network: ${chainName(chainId)} (${isTestEnvironment ? 'local' : 'remote'})`);
    console.log(`Deployer: ${deployer}`);

    console.log(`\nDeploying CounterFactualWallet Controller...`);
    const controllerResult = await deploy('CounterfactualWalletController', {
        from: deployer,
    });

    console.log('CounterFact', controllerResult);


};