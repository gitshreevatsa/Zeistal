// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IStorkVerifier {
    function verifyStorkSignatureV1(
        address storkPubKey,
        bytes32 id,
        uint256 recvTime,
        int256 quantizedValue,
        bytes32 publisherMerkleRoot,
        bytes32 valueComputeAlgHash,
        uint256 value,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external returns (bool);
}

// USDC address : 0xb669dC8cC6D044307Ba45366C0c836eC3c7e31AA
// WBTC Address : 0x8d0c9d1c17aE5e40ffF9bE350f57840E9E66Cd93
// Uniswap Router : 0xb45670f668EE53E62b5F170B5B1d3C6701C8d03A

contract LendingPool {
    address public usdcToken = 0xb669dC8cC6D044307Ba45366C0c836eC3c7e31AA;
    address public wbtctoken = 0x8d0c9d1c17aE5e40ffF9bE350f57840E9E66Cd93;
    address public uniswapRouter = 0xb45670f668EE53E62b5F170B5B1d3C6701C8d03A;
    address public storkVerifier = 0xacC0a0cF13571d30B4b8637996F5D6D774d4fd62;
    uint256 public poolBalance;
    uint256 public exchangeRate; // USDC per BTC

    struct Lender {
        uint256 deposit;
        uint256 totalContributed;
        uint256 btcEquivalent; // BTC amount they’re entitled to receive
    }

    struct Deposit {
        bytes32 id;
        address lender;
        uint256 amount;
        uint256 duration;
        uint256 interest;
        uint256 depositBalance;
        uint256 receieveAmount;
        uint256 price;
    }

    struct Loan {
        bytes32 id;
        uint256 amount;
        uint256 collateral;
        address borrower;
        address[] lenders;
        uint256[] amounts;
        uint256 remainingCollateral;
        bool isActive;
    }

    mapping(address => Lender) public lenders;
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256) public assetPrice;
    uint256 public loanCount;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    event DepositEvent(
        bytes32 id,
        address indexed lender,
        uint256 amount,
        uint256 duration,
        uint256 interest,
        uint256 depositBalance
    );

    function setPrice(
        address asset,
        address storkPubKey,
        bytes32 id,
        uint256 recvTime,
        int256 quantizedValue,
        bytes32 publisherMerkleRoot,
        bytes32 valueComputeAlgHash,
        uint256 value,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        bool result = IStorkVerifier(storkVerifier).verifyStorkSignatureV1(
            storkPubKey,
            id,
            recvTime,
            quantizedValue,
            publisherMerkleRoot,
            valueComputeAlgHash,
            value,
            r,
            s,
            v
        );

        if (result) {
            exchangeRate = value;
            assetPrice[asset] = value;
        }
    }

    function getPrice(address asset) external view returns (uint256) {
        return assetPrice[asset];
    }

    // Deposit function for lenders
    function deposit(
        address asset,
        uint256 amount,
        uint256 interest,
        uint256 duration
    ) external returns (Deposit memory) {
        // Get Price of Asset
        uint256 price = assetPrice[asset];
        // Transfer USDC from lender to contract
        ERC20(usdcToken).transferFrom(msg.sender, address(this), amount);
        // Create a unique ID for the deposit
        bytes32 id = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        // Update the lender’s deposit balance
        lenders[msg.sender].deposit += amount;
        // Update pool's balance
        poolBalance += amount;
        // Calculate the amount the lender will receive after the duration
        uint256 receieveAmount = amount + (amount * interest) / 100;
        // Create a deposit object
        Deposit memory depositAction = Deposit(
            id,
            msg.sender,
            amount,
            duration,
            interest,
            poolBalance,
            receieveAmount,
            price
        );
        // Emit a deposit event
        emit DepositEvent(
            id,
            msg.sender,
            amount,
            duration,
            interest,
            poolBalance
        );

        return depositAction;
    }
}

// Create a loan function: Iterate over the lenders whose deposits are available for the given duration and calculate how much collateral they can provide and
// then create a loan object by calculating each lenders contribution ratio
// and the net receivables based on the interest rate of loan and the total receivables per lender with total principal, total interest and total amount and the liquidation factor based on collateral

// A function to give available liquidity for a given time duration

