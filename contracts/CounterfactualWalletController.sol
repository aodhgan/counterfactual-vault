// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

import "./external/pooltogether/MinimalProxyLibrary.sol";
import "./CounterfactualWallet.sol";

/// @title Allows users to plunder an address associated with an ERC721
/// @notice Counterfactually instantiates a "Loot Box" at an address unique to an ERC721 token.  The address for an ERC721 token can be computed and later
/// plundered by transferring token balances to the ERC721 owner.
contract CounterfactualWalletController is Ownable {
    /// @notice The instance to which all proxies will point
    CounterfactualWallet public lootBoxInstance;

    bytes32 internal immutable _counterfactualWalletBytecodeHash;
    bytes internal _counterfactualWalletBytecode;

    /// @notice Emitted when a Loot Box is plundered
    event Plundered(
        address indexed erc721,
        uint256 indexed tokenId,
        address indexed operator
    );

    /// @notice Emitted when a Loot Box is executed
    event Executed(
        address indexed erc721,
        uint256 indexed tokenId,
        address indexed operator
    );

    /// @notice Constructs a new controller.
    /// @dev Creates a new CounterfactualWallet instance and an associated minimal proxy.
    constructor() Ownable() {
        lootBoxInstance = new CounterfactualWallet();
        lootBoxInstance.initialize();
        _counterfactualWalletBytecode = MinimalProxyLibrary.minimalProxy(
            address(lootBoxInstance)
        );
        _counterfactualWalletBytecodeHash = keccak256(
            _counterfactualWalletBytecode
        );
    }

    /// @notice Allows owner to transfer all given tokens in a Loot Box to a destination address
    /// @dev A Loot Box contract will be counterfactually created, tokens transferred to the owner, then destroyed.
    /// @param erc721 The address of the ERC721
    /// @param tokenId The ERC721 token id
    /// @param erc20s An array of ERC20 tokens whose entire balance should be transferred
    /// @param erc721s An array of structs defining ERC721 tokens that should be transferred
    function sweep(
        address payable erc721,
        uint256 tokenId,
        IERC20[] calldata erc20s,
        CounterfactualWallet.WithdrawERC721[] calldata erc721s
    ) external onlyOwner {
        CounterfactualWallet counterfactualWallet = _createLootBox(
            erc721,
            tokenId
        );

        counterfactualWallet.plunder(erc20s, erc721s, erc721);
        counterfactualWallet.destroy(erc721);

        emit Plundered(erc721, tokenId, msg.sender);
    }

    /// @notice Allows the owner of an ERC721 to execute abitrary calls on behalf of the associated Loot Box.
    /// @dev The Loot Box will be counterfactually created, calls executed, then the contract destroyed.
    /// @param erc721 The ERC721 address
    /// @param tokenId The ERC721 token id
    /// @param calls The array of call structs that define that target, amount of ether, and data.
    /// @return The array of call return values.
    function executeCalls(
        address erc721,
        uint256 tokenId,
        CounterfactualWallet.Call[] calldata calls
    ) external returns (bytes[] memory) {
        address payable owner = payable(IERC721(erc721).ownerOf(tokenId));
        require(msg.sender == owner, "CFWController/only-owner");
        CounterfactualWallet counterfactualWallet = _createLootBox(
            erc721,
            tokenId
        );
        bytes[] memory result = counterfactualWallet.executeCalls(calls);
        counterfactualWallet.destroy(owner);

        emit Executed(erc721, tokenId, msg.sender);

        return result;
    }

    /// @notice Computes the Counterfactual Wallet address for an address.
    /// @dev The contract will not exist yet, so the address will have no code.
    /// @param owner The address of the owner
    /// @param walletId The walletId ("HD wallet" nonce)
    /// @return The address of the Counterfactual Wallet
    function computeAddress(address owner, uint256 walletId)
        external
        view
        returns (address)
    {
        return
            Create2Upgradeable.computeAddress(
                _salt(owner, walletId),
                _counterfactualWalletBytecodeHash
            );
    }

    /// @notice Creates a CounterfactualWallet for the given owners address.
    /// @param owner The ERC721 address
    /// @param walletId The ERC721 token id
    /// @return The address of the newly created CounterfactualWallet.
    function _createLootBox(address owner, uint256 walletId)
        internal
        returns (CounterfactualWallet)
    {
        CounterfactualWallet counterfactualWallet = CounterfactualWallet(
            Create2Upgradeable.deploy(
                0,
                _salt(owner, walletId),
                _counterfactualWalletBytecode
            )
        );
        counterfactualWallet.initialize();
        return counterfactualWallet;
    }

    /// @notice Computes the CREATE2 salt for the given ERC721 token.
    /// @param owner The owners address
    /// @param walletId The walletId
    /// @return A bytes32 value that is unique to that ERC721 token.
    function _salt(address owner, uint256 walletId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, walletId));
    }
}
