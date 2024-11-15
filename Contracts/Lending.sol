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

contract LendingPool {
    address public usdcToken;
    address public wbtctoken;
    address public uniswapRouter;
    uint256 public poolBalance;
    uint256 public exchangeRate; // USDC per WETH

    struct Lender {
        uint256 deposit;
        uint256 totalContributed;
        uint256 wethEquivalent; // WETH amount they’re entitled to receive
    }

    struct Loan {
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
    uint256 public loanCount;

    constructor(
        address _usdcToken,
        address _wbtctoken,
        address _uniswapRouter
    ) {
        usdcToken = _usdcToken;
        wbtctoken = _wbtctoken;
        uniswapRouter = _uniswapRouter;
    }

    // Deposit function for lenders
    function deposit(uint256 amount) external {
        // Assume approval has been given by the lender
        ERC20(usdcToken).transferFrom(msg.sender, address(this), amount);
        lenders[msg.sender].deposit += amount;
        poolBalance += amount;
    }

    // Open a new loan with USDC collateral
    function openLoan(uint256 amount, uint256 collateral) external {
        require(poolBalance >= (amount * 80) / 100, "Not enough liquidity");

        // Store the USDC to WETH exchange rate when loan is opened
        exchangeRate = 5*amount; // As 20% of the loan amount is bought by borrower and protocol supports only 1BTC trades ATM

        Loan storage loan = loans[loanCount];
        loan.amount = amount;
        loan.collateral = collateral;
        loan.remainingCollateral = collateral;
        loan.borrower = msg.sender;
        loan.isActive = true;

        // Allocate lenders to this loan
        allocateLendersToLoan(loanCount, amount);

        // Swap 80% of the loan amount (in USDC) for WETH and send to borrower
        uint256 usdcToSwap = (amount * 80) / 100;
        swapUSDCForWETH(usdcToSwap, msg.sender);

        loanCount++;
    }

    // Allocate funds from lenders to the loan
    function allocateLendersToLoan(uint256 loanId, uint256 amount) internal {
        Loan storage loan = loans[loanId];
        uint256 totalAllocated = 0;
        address[] memory lenderAddresses = getLendersWithContribution();

        for (uint256 i = 0; i < lenderAddresses.length; i++) {
            address lenderAddr = lenderAddresses[i];
            Lender storage lender = lenders[lenderAddr];
            uint256 contribution = (amount * lender.deposit) / poolBalance;

            if (totalAllocated + contribution > amount) {
                contribution = amount - totalAllocated;
            }

            lender.deposit -= contribution;
            lender.totalContributed += contribution;

            // Calculate WETH equivalent for lender’s contribution
            uint256 wethEquivalent = (contribution * 1 ether) / exchangeRate;
            lender.wethEquivalent += wethEquivalent;

            loan.lenders.push(lenderAddr);
            loan.amounts.push(contribution);

            totalAllocated += contribution;
            if (totalAllocated >= amount) break;
        }

        poolBalance -= totalAllocated;
    }

    // Process a payment towards a loan
    function processPayment(uint256 loanId, uint256 amount) external {
        Loan storage loan = loans[loanId];
        require(loan.isActive, "Loan is not active");

        ERC20(usdcToken).transferFrom(msg.sender, address(this), amount);

        // Distribute payment to lenders
        for (uint256 i = 0; i < loan.lenders.length; i++) {
            address lenderAddr = loan.lenders[i];
            uint256 lenderContribution = loan.amounts[i];
            uint256 lenderShare = (amount * lenderContribution) / loan.amount;

            lenders[lenderAddr].deposit += lenderShare;
        }

        // Reduce the loan's remaining collateral as payment is made
        loan.remainingCollateral -= (loan.collateral * amount) / loan.amount;

        // If loan is fully paid, deactivate it
        if (loan.remainingCollateral == 0) {
            loan.isActive = false;
        }
    }

    // Swap function (USDC -> WETH) via Uniswap
    function swapUSDCForWETH(uint256 amount, address to) internal {
        ERC20(usdcToken).approve(uniswapRouter, amount);

        address[] memory path;
        path[0] = usdcToken;
        path[1] = wbtctoken;

        IUniswap(uniswapRouter).swapExactTokensForTokens(
            amount,
            1, // Min amount out, could use slippage tolerance
            path,
            to,
            block.timestamp
        );
    }

    // Get the list of lenders with contributions
    function getLendersWithContribution()
        internal
        view
        returns (address[] memory)
    {
        // Implementation to return all lenders with non-zero deposits
    }
}
