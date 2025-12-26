// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AuthorizationManager
 * @notice Validates off-chain withdrawal authorizations and prevents reuse
 */
contract AuthorizationManager is Ownable {
    using ECDSA for bytes32;

    /// @dev Tracks whether an authorization has already been consumed
    mapping(bytes32 => bool) public authorizationUsed;

    /// @notice Emitted when an authorization is consumed
    event AuthorizationConsumed(
        bytes32 indexed authorizationId,
        address indexed vault,
        address indexed recipient,
        uint256 amount
    );

    constructor(address admin) {
        _transferOwnership(admin);
    }

    /**
     * @notice Verifies whether a withdrawal is authorized
     * @param vault Vault contract address
     * @param recipient Withdrawal recipient
     * @param amount Withdrawal amount
     * @param nonce Unique authorization nonce
     * @param signature Off-chain signature
     */
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external returns (bool) {
        bytes32 authorizationId = getAuthorizationId(
            vault,
            recipient,
            amount,
            nonce
        );

        // Authorization must not be reused
        require(!authorizationUsed[authorizationId], "Authorization already used");

        // Build deterministic message
        bytes32 messageHash = keccak256(
            abi.encode(
                vault,
                block.chainid,
                recipient,
                amount,
                nonce
            )
        ).toEthSignedMessageHash();

        // Recover signer
        address signer = messageHash.recover(signature);

        // Only trusted signer (owner) can authorize
        require(signer == owner(), "Invalid authorization signature");

        // Mark authorization as consumed BEFORE returning
        authorizationUsed[authorizationId] = true;

        emit AuthorizationConsumed(
            authorizationId,
            vault,
            recipient,
            amount
        );

        return true;
    }

    /**

     * @notice Computes unique authorization identifier
     */
    function getAuthorizationId(
        address vault,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(vault, recipient, amount, nonce)
        );
    }
}
