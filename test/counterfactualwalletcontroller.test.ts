/* eslint-disable */
// Start - Support direct Mocha run & debug
import 'hardhat'
import '@nomiclabs/hardhat-ethers'
// End - Support direct Mocha run & debug

import chai, { expect } from 'chai'
import { before } from 'mocha'
import { solidity } from 'ethereum-waffle'
import { CounterfactualWalletController } from '../typechain-types'
import { deployContract, signer } from './framework/contracts'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { ERC20PresetMinterPauser, ERC20PresetMinterPauserInterface } from '../typechain-types/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser'
import { TransactionReceipt } from '@ethersproject/abstract-provider'
import { deployments, ethers } from 'hardhat'
import { TransactionRequest } from '@ethersproject/providers'
import { Contract } from 'ethers'
// Wires up Waffle with Chai
chai.use(solidity)

describe('LootBoxController', () => {
    before(async () => {
        admin = await signer(0)
        observer = await signer(1)
    })

    beforeEach(async () => {
        counterfactualWalletController = await deployContract(
            'CounterfactualWalletController',
            []
        )

        exampleErc20 = await deployContract('ERC20PresetMinterPauser', [
            'Example',
            'EXM'
        ])
        console.log('deployed erc20 at ', exampleErc20.address)
    })


    describe('deployment gas ', async () => {
        it("displays gas used to deploy CFWController", async () => {
            // get amount of gas it takes to deploy a CounterfactualWalletController
            const factory = await ethers.getContractFactory("CounterfactualWalletController", observer)

            // get deployment tx receipt
            const deployTxReceipt: Contract = await factory.deploy()
            const deployTx = await deployTxReceipt.deployTransaction.wait()
            console.log("gas used to deploy CFWController:", deployTx.gasUsed.toString())
        })
    })


    describe('execute call', () => {
        it('owner can execute erc20::transfer call', async () => {

            // this makes "sweep()" redundant

            const TWO = 2
            const calculatedAddress2 =
                await counterfactualWalletController.computeAddress(TWO)
            console.log({ calculatedAddress2 })

            // mint tokens to calculated address2
            const mintAmount = 7000
            await exampleErc20.mint(calculatedAddress2, mintAmount)

            await counterfactualWalletController.executeCalls(admin.address, TWO,
                [{ to: exampleErc20.address, value: 0, data: exampleErc20.interface.encodeFunctionData("transfer", [observer.address, mintAmount]) }])

            expect(await exampleErc20.balanceOf(calculatedAddress2)).to.equal(0)
            expect(await exampleErc20.balanceOf(observer.address)).to.equal(
                mintAmount
            )

        })
    })
    let admin: SignerWithAddress
    let observer: SignerWithAddress
    let counterfactualWalletController: CounterfactualWalletController
    let exampleErc20: ERC20PresetMinterPauser
})
