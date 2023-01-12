import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@openzeppelin/hardhat-upgrades'
import '@nomiclabs/hardhat-waffle'
import '@windranger-io/windranger-tools-hardhat'
import 'hardhat-deploy'
import 'hardhat-deploy-ethers'
import networks from './hardhat.network'


/*
 * You need to export an object to set up your config
 * Go to https://hardhat.org/config/ to learn more
 *
 * At time of authoring 0.8.4 was the latest version supported by Hardhat
 */
export default {
    networks,
    solidity: {
        compilers: [
            {
                version: '0.7.6',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },
            {
                version: '0.8.4'
            },
            {
                version: '0.6.12'
            }
        ]
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    }
}