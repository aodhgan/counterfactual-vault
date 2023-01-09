/* eslint-disable */
// Start - Support direct Mocha run & debug
import 'hardhat'
import '@nomiclabs/hardhat-ethers'
// End - Support direct Mocha run & debug

import chai, {expect} from 'chai'
import {before} from 'mocha'
import {solidity} from 'ethereum-waffle'
import {LootBoxController} from '../typechain-types'
import {deployContract, signer} from './framework/contracts'
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers'
import {ERC20PresetMinterPauser} from '../typechain-types/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser'

// Wires up Waffle with Chai
chai.use(solidity)

// Start with the contract name as the top level descriptor
describe('LootBoxController', () => {
    /*
     * Once and before any test, get a handle on the signer and observer
     * (only put variables in before, when their state is not affected by any test)
     */
    before(async () => {
        admin = await signer(0)
        observer = await signer(1)
    })

    // Before each test, deploy a fresh box (clean starting state)
    beforeEach(async () => {
        lootBoxController = await deployContract('LootBoxController', [])

        exampleErc20 = await deployContract('ERC20PresetMinterPauser', [
            'Example',
            'EXM'
        ])
        console.log('deployed erc20 at ', exampleErc20.address)
    })

    // Inner describes use the name or idea for the function they're unit testing
    describe('store', () => {
        /*
         * Describe 'it', what unit of logic is being tested
         * Keep in mind the full composition of the name: Box > store > value
         */
        it('value', async () => {
            const calculatedAddress = await lootBoxController.computeAddress(
                admin.address,
                1
            )
            console.log({calculatedAddress})

            const calculatedAddress2 = await lootBoxController.computeAddress(
                admin.address,
                2
            )
            console.log({calculatedAddress2})

            // mint tokens to calculated address2
            const mintAmount = 7000
            await exampleErc20.mint(calculatedAddress2, mintAmount)
            console.log(
                'balance of calculatedAddress2 ',
                await exampleErc20.balanceOf(calculatedAddress2)
            )

            // plunder tokens from calculatedAddress2 to observer
            await lootBoxController.plunder(
                admin.address,
                2,
                [exampleErc20.address],
                []
            )
            console.log(
                'balance of calculatedAddress2 now ',
                await exampleErc20.balanceOf(calculatedAddress2)
            )
            expect(await exampleErc20.balanceOf(calculatedAddress2)).to.equal(0)
            expect(await exampleErc20.balanceOf(admin.address)).to.equal(
                mintAmount
            )
        })
    })

    // Inner describes use the name or idea for the function they're unit testing
    describe.only('random cannot plunder', () => {
        it('value', async () => {
            const calculatedAddress2 = await lootBoxController.computeAddress(
                admin.address,
                2
            )
            console.log({calculatedAddress2})

            // mint tokens to calculated address2
            const mintAmount = 7000
            await exampleErc20.mint(calculatedAddress2, mintAmount)
            console.log(
                'balance of calculatedAddress2 ',
                await exampleErc20.balanceOf(calculatedAddress2)
            )

            // plunder tokens from calculatedAddress2 to observer
            await expect(
                lootBoxController
                    .connect(observer)
                    .plunder(admin.address, 2, [exampleErc20.address], [])
            ).to.be.revertedWith('Ownable: caller is not the owner')
            console.log(
                'balance of calculatedAddress2 now ',
                await exampleErc20.balanceOf(calculatedAddress2)
            )
            expect(await exampleErc20.balanceOf(calculatedAddress2)).to.equal(
                mintAmount
            )
            expect(await exampleErc20.balanceOf(admin.address)).to.equal(0)
        })
    })
    let admin: SignerWithAddress
    let observer: SignerWithAddress
    let lootBoxController: LootBoxController
    let exampleErc20: ERC20PresetMinterPauser
})
