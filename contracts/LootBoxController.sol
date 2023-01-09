// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

import "./external/pooltogether/MinimalProxyLibrary.sol";
import "./LootBox.sol";

/// @title Allows users to plunder an address associated with an ERC721
/// @notice Counterfactually instantiates a "Loot Box" at an address unique to an ERC721 token.  The address for an ERC721 token can be computed and later
/// plundered by transferring token balances to the ERC721 owner.
contract LootBoxController is Ownable {
    /// @notice The instance to which all proxies will point
    LootBox public lootBoxInstance;

    bytes32 internal immutable lootBoxBytecodeHash;
    bytes internal lootBoxBytecode;

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
    /// @dev Creates a new LootBox instance and an associated minimal proxy.
    constructor() Ownable() {
        lootBoxInstance = new LootBox();
        lootBoxInstance.initialize();
        lootBoxBytecode = MinimalProxyLibrary.minimalProxy(
            address(lootBoxInstance)
        );
        lootBoxBytecodeHash = keccak256(lootBoxBytecode);
    }

    /// @notice Computes the Loot Box address for a given ERC721 token.
    /// @dev The contract will not exist yet, so the Loot Box address will have no code.
    /// @param erc721 The address of the ERC721
    /// @param tokenId The ERC721 token id
    /// @return The address of the Loot Box.
    function computeAddress(address erc721, uint256 tokenId)
        external
        view
        returns (address)
    {
        return
            Create2Upgradeable.computeAddress(
                _salt(erc721, tokenId),
                lootBoxBytecodeHash
            );
    }

    /// @notice Allows anyone to transfer all given tokens in a Loot Box to the associated ERC721 owner.
    /// @dev A Loot Box contract will be counterfactually created, tokens transferred to the ERC721 owner, then destroyed.
    /// @param erc721 The address of the ERC721
    /// @param tokenId The ERC721 token id
    /// @param erc20s An array of ERC20 tokens whose entire balance should be transferred
    /// @param erc721s An array of structs defining ERC721 tokens that should be transferred
    function plunder(
        address payable erc721,
        uint256 tokenId,
        IERC20[] calldata erc20s,
        LootBox.WithdrawERC721[] calldata erc721s
    ) external onlyOwner {
        console.log("plundering..");

        // address payable owner = payable(IERC721(erc721).ownerOf(tokenId));
        LootBox lootBox = _createLootBox(erc721, tokenId);
        console.log("created lootbox at ", address(lootBox));

        lootBox.plunder(erc20s, erc721s, erc721);
        lootBox.destroy(erc721);

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
        LootBox.Call[] calldata calls
    ) external returns (bytes[] memory) {
        address payable owner = payable(IERC721(erc721).ownerOf(tokenId));
        require(msg.sender == owner, "LootBoxController/only-owner");
        LootBox lootBox = _createLootBox(erc721, tokenId);
        bytes[] memory result = lootBox.executeCalls(calls);
        lootBox.destroy(owner);

        emit Executed(erc721, tokenId, msg.sender);

        return result;
    }

    /// @notice Creates a Loot Box for the given ERC721 token.
    /// @param erc721 The ERC721 address
    /// @param tokenId The ERC721 token id
    /// @return The address of the newly created LootBox.
    function _createLootBox(address erc721, uint256 tokenId)
        internal
        returns (LootBox)
    {
        LootBox lootBox = LootBox(
            Create2Upgradeable.deploy(
                0,
                _salt(erc721, tokenId),
                lootBoxBytecode
            )
        );
        lootBox.initialize();
        return lootBox;
    }

    /// @notice Computes the CREATE2 salt for the given ERC721 token.
    /// @param erc721 The ERC721 address
    /// @param tokenId The ERC721 token id
    /// @return A bytes32 value that is unique to that ERC721 token.
    function _salt(address erc721, uint256 tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(erc721, tokenId));
    }
}
