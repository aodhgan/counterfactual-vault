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



        // console.log("gas to deploy CounterfactualWalletController", deployTx.ga)

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

    describe('sweeping', () => {
        it('deployment gas ', async () => {
            // get amount of gas it takes to deploy a CounterfactualWalletController
            const factory = await ethers.getContractFactory("CounterfactualWalletController", observer)

            // get deployment tx receipt
            const deployTxReceipt: Contract = await factory.deploy()
            const deployTx = await deployTxReceipt.deployTransaction.wait()
            console.log("gas used to deploy CFWController:", deployTx.gasUsed.toString())
        })


        it('can sweep', async () => {
            const calculatedAddress =
                await counterfactualWalletController.computeAddress(1)

            const calculatedAddress2 =
                await counterfactualWalletController.computeAddress(2)
            // mint tokens to calculated address2
            const mintAmount = 7000
            await exampleErc20.mint(calculatedAddress2, mintAmount)

            // sweep tokens from calculatedAddress2 to observer
            const result = await counterfactualWalletController.sweep(
                2,
                admin.address,
                [exampleErc20.address],
                []
            )
            const receipt = await result.wait()
            console.log('gas used', receipt.gasUsed.toString())
            console.log(
                'balance of calculatedAddress2 now ',
                await exampleErc20.balanceOf(calculatedAddress2)
            )
            expect(await exampleErc20.balanceOf(calculatedAddress2)).to.equal(0)
            expect(await exampleErc20.balanceOf(admin.address)).to.equal(
                mintAmount
            )
        })
        it('benchmark standard erc20 transfer', async () => {
            const mintAmount = 100
            await exampleErc20.mint(admin.address, mintAmount)
            const result = await exampleErc20.transfer(
                observer.address,
                mintAmount
            )
            const receipt = await result.wait()
            console.log('gas used', receipt.gasUsed.toString())
        })
    })

    describe('random cannot sweep', () => {
        it('cannot sweep', async () => {
            const calculatedAddress2 =
                await counterfactualWalletController.computeAddress(2)
            console.log({ calculatedAddress2 })

            // mint tokens to calculated address2
            const mintAmount = 7000
            await exampleErc20.mint(calculatedAddress2, mintAmount)
            // plunder tokens from calculatedAddress2 to observer
            await expect(
                counterfactualWalletController
                    .connect(observer)
                    .sweep(2, observer.address, [exampleErc20.address], [])
            ).to.be.revertedWith('Ownable: caller is not the owner')
            expect(await exampleErc20.balanceOf(calculatedAddress2)).to.equal(
                mintAmount
            )
            expect(await exampleErc20.balanceOf(admin.address)).to.equal(0)

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
