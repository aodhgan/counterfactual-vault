// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title
/// @notice A CounterfactualWallet allows anyone to withdraw all tokens or execute calls on behalf of the contract.
/// @dev This contract is intended to be counterfactually instantiated via CREATE2.
contract CounterfactualWallet {
    /// @notice A structure to define arbitrary contract calls
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    /// @notice A structure to define ERC721 transfer contents
    struct WithdrawERC721 {
        IERC721 token;
        uint256[] tokenIds;
    }

    /// @notice A structure to define ERC1155 transfer contents
    struct WithdrawERC1155 {
        IERC1155 token;
        uint256[] ids;
        uint256[] amounts;
        bytes data;
    }

    address private _owner;

    /// @notice Emitted when an ERC20 token is withdrawn
    event WithdrewERC20(address indexed token, uint256 amount);

    /// @notice Emitted when an ERC721 token is withdrawn
    event WithdrewERC721(address indexed token, uint256[] tokenIds);

    /// @notice Emitted when the contract transfer ether
    event TransferredEther(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == _owner, "CounterfactualWallet/only-owner");
        _;
    }

    function initialize() external {
        require(_owner == address(0), "CounterfactualWallet/already-init");
        _owner = msg.sender;
    }

    /// @notice Executes calls on behalf of this contract.
    /// @param calls The array of calls to be executed.
    /// @return An array of the return values for each of the calls
    function executeCalls(Call[] calldata calls)
        external
        onlyOwner
        returns (bytes[] memory)
    {
        bytes[] memory response = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            response[i] = _executeCall(
                calls[i].to,
                calls[i].value,
                calls[i].data
            );
        }
        return response;
    }

    function sweep(
        IERC20[] memory erc20,
        WithdrawERC721[] memory erc721,
        address payable to
    ) external onlyOwner {
        require(to != address(0), "CounterfactualWallet/non-zero-to");
        _withdrawERC20(erc20, to);
        _withdrawERC721(erc721, to);
        _transferEther(to, address(this).balance);
    }

    /// @notice Destroys this contract using `selfdestruct`
    /// @param to The address to send remaining Ether to
    function destroy(address payable to) external onlyOwner {
        delete _owner;
        selfdestruct(to);
    }

    /// @notice Transfers ether held by the contract to another account
    /// @param to The account to transfer Ether to
    /// @param amount The amount of Ether to transfer
    function _transferEther(address payable to, uint256 amount) internal {
        to.transfer(amount);

        emit TransferredEther(to, amount);
    }

    /// @notice Executes a call to another contract
    /// @param to The address to call
    /// @param value The Ether to pass along with the call
    /// @param data The call data
    /// @return The return data from the call
    function _executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool succeeded, bytes memory returnValue) = to.call{value: value}(
            data
        );
        require(succeeded, string(returnValue));
        return returnValue;
    }

    /// @notice Transfers the entire balance of ERC20s to an account
    /// @param tokens An array of ERC20 tokens to transfer out.  The balance of each will be transferred.
    /// @param to The recipient of the transfers
    function _withdrawERC20(IERC20[] memory tokens, address to) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(address(this));
            tokens[i].transfer(to, balance);

            emit WithdrewERC20(address(tokens[i]), balance);
        }
    }

    /// @notice Transfers ERC721 tokens to an account
    /// @param withdrawals An array of WithdrawERC721 structs that each include the ERC721 token to transfer and the corresponding token ids.
    /// @param to The recipient of the transfers
    function _withdrawERC721(WithdrawERC721[] memory withdrawals, address to)
        internal
    {
        for (uint256 i = 0; i < withdrawals.length; i++) {
            for (
                uint256 tokenIndex = 0;
                tokenIndex < withdrawals[i].tokenIds.length;
                tokenIndex++
            ) {
                withdrawals[i].token.transferFrom(
                    address(this),
                    to,
                    withdrawals[i].tokenIds[tokenIndex]
                );
            }

            emit WithdrewERC721(
                address(withdrawals[i].token),
                withdrawals[i].tokenIds
            );
        }
    }
}
