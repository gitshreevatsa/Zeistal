// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Lending {
    address public token;
    address public owner;
    address public router;

    constructor(address _token, address _router) {
        token = _token;
        owner = msg.sender;
        router = _router;
    }

    struct Loan {
        bytes32 loanid;
        address[] lenders;
        uint256[] amounts;
        uint256 total_amount;
        uint256 duration;
        uint256 start_date;
        uint256 end_date;
        uint256 monthsNotPaid;
        uint256 upFrontPayment;
        bool active;
        bool slashed;
        Payment[] payments;
    }

    struct Payment {
        bytes32 paymentId;
        bytes32 loanId;
        address[] userAddress;
        uint256[] amounts;
    }

    mapping(bytes32 => Loan) public loans;
    mapping(bytes32 => Payment) public payments;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function loan(
        bytes32 loanid,
        address[] memory lenders,
        uint256[] memory amounts,
        uint256 total_amount,
        uint256 duration,
        uint256 start_date,
        uint256 end_date,
        uint256 monthsNotPaid,
        uint256 upFrontPayment
    ) public {
        Loan storage loanDetails = loans[loanid];
        loanDetails.loanid = loanid;
        loanDetails.lenders = lenders;
        loanDetails.amounts = amounts;
        loanDetails.total_amount = total_amount;
        loanDetails.duration = duration;
        loanDetails.start_date = start_date;
        loanDetails.end_date = end_date;
        loanDetails.monthsNotPaid = monthsNotPaid;
        loanDetails.active = true;
        loanDetails.slashed = false;
        loanDetails.upFrontPayment = upFrontPayment;

        // Loop for transferring tokens from lenders to contract
        for (uint256 i = 0; i < lenders.length; i++) {
            ERC20(token).transferFrom(lenders[i], address(this), amounts[i]);
        }

        // Path for swapping tokens (static values here, should be parameterized)
        address[] memory path;
        path[0] = 0xb669dC8cC6D044307Ba45366C0c836eC3c7e31AA;
        path[1] = 0x8d0c9d1c17aE5e40ffF9bE350f57840E9E66Cd93;

        // Perform swap
        IRouter(router).swapExactTokensForETH(
            loanDetails.total_amount,
            1, // Minimum amount of ETH to receive
            path,
            address(this),
            block.timestamp + 10
        );
    }

    function payment(
        bytes32 paymentId,
        bytes32 loanId,
        address[] memory userAddress,
        uint256[] memory amounts
    ) public {
        Payment memory paymentDetails;
        paymentDetails.paymentId = paymentId;
        paymentDetails.loanId = loanId;
        paymentDetails.userAddress = userAddress;
        paymentDetails.amounts = amounts;

        // Store the payment details
        Loan storage loanDetails = loans[loanId];
        loanDetails.payments.push(paymentDetails);
        payments[paymentId] = paymentDetails;

        // Transfer amounts to users
        for (uint256 i = 0; i < userAddress.length; i++) {
            ERC20(token).transfer(userAddress[i], amounts[i]);
        }
    }

    function slash(
        bytes32 loanId,
        address[] memory userAddresses,
        uint256[] memory amounts
    ) public onlyOwner {
        Loan storage loanDetails = loans[loanId];
        loanDetails.slashed = true;

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // Path for swapping tokens (static values here, should be parameterized)
        address[] memory path;
        path[0] = 0xb669dC8cC6D044307Ba45366C0c836eC3c7e31AA;
        path[1] = 0x8d0c9d1c17aE5e40ffF9bE350f57840E9E66Cd93;

        // Perform swap
        IRouter(router).swapExactETHForTokens(
            totalAmount,
            path,
            address(this),
            block.timestamp + 10
        );

        // Transfer amounts to the user addresses
        for (uint256 i = 0; i < userAddresses.length; i++) {
            ERC20(token).transfer(userAddresses[i], amounts[i]);
        }
    }
}
