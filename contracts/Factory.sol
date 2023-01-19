// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// import "./external/lib/MinimalProxyFactory.sol";
// import "./CounterfactualWalletController.sol";

// contract Factory {
//     address public immutable counterfactualWalletController;

//     constructor(address _counterfactualWalletController) {
//         counterfactualWalletController = _counterfactualWalletController;
//     }

//     function createCounterfactualWalletController() external returns (address) {
//         CounterfactualWalletController _cfwc = MinimalProxyFactory.create(counterfactualWalletController);
//         // then initialize
//         CounterfactualWalletController.initialize();
//     }
// }
