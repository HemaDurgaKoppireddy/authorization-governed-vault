// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @notice Minimal interface for AuthorizationManager
 * Vault must rely exclusively on this contract for permission validation
 */
interface IAuthorizationManager {
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external returns (bool);
}

/**
 * @title SecureVault
 * @notice Holds ETH and executes withdrawals only after authorization
 */
contract SecureVault {
    /// @notice Authorization manager contract
    IAuthorizationManager public immutable authorizationManager;

    /// @notice Emitted when ETH is deposited
    event Deposit(address indexed from, uint256 amount);

    /// @notice Emitted when ETH is withdrawn
    event Withdrawal(address indexed to, uint256 amount);

    constructor(address authManager) {
        require(authManager != address(0), "Invalid authorization manager");
        authorizationManager = IAuthorizationManager(authManager);
    }

    /**
     * @notice Accept ETH deposits from any address
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH after authorization validation
     * @param recipient Receiver of ETH
     * @param amount Amount to withdraw
     * @param nonce Unique authorization nonce
     * @param signature Off-chain authorization signature
     */
    function withdraw(
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(address(this).balance >= amount, "Insufficient vault balance");

        // Request authorization validation (external call)
        bool authorized = authorizationManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            nonce,
            signature
        );

        require(authorized, "Authorization failed");

        // Interaction AFTER all checks
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawal(recipient, amount);
    }
}
