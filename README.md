# Citrea HH - Zeistal Project

## Overview

This project provides the backend for interacting with the Zeistal platform. The API allows users to authenticate, lend, get liquidity, borrow, and interact with contracts with the respinses. All of the calculations are handled here with the responses serving as the indexable data points without any calculations required.

## User Stories

### 1. Authentication

Users must authenticate before accessing other endpoints.

**Endpoint:** `GET /api/auth/nonce`

**Request Body:**

```json
{
  "address": "0x1234567890abcdef1234567890abcdef12345678"
}
```

**Response:**

```json
{
  "token": "your-temp-auth-token",
  "nonce": "your-nonce"
}
```

**Endpoint:** `POST /api/auth/verify`

**Request Body:**

```json
{
  "tempToken": "your-temp-auth-token",
  "signature": "your-signature"
}
```

**Response:**

```json
{
  "status": "success"
}
```

### 2. Lenders - Lend

Authenticated users can lend funds.

**Endpoint:** `POST /lending/`

**Request Body:**

```json
{
  "user_address": "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
  "lending_amount_approved": 10000,
  "lending_duration": 63072000,
  "interest_rate": 5,
  "amount_receivable": 10500,
  "interest": 500
}
```

**Response:**

```json
{
  "message": "Lending created successfully"
}
```

### 3. Borrowers - Get Liquidity

Authenticated users can check available liquidity.

**Endpoint:** `GET /loan/check/liquidity`

**Request Params:**

```json
{
  "duration": 15552000,
  "amount": 1000
}
```

**Response:**

```json
{
  "message": "Liquidity available",
  "success": true,
  "totalAvailableLiquidity": 99999999999999920000
}
```

### 4. Borrowers - Borrow

Authenticated users can borrow funds.

**Endpoint:** `POST /loan`

**Request Body:**

```json
{
  "user_address": "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  "loan_amount": 10000,
  "up_front_payment": 2000,
  "interest": 500,
  "interest_rate": 5,
  "total_amount_payable": 10500,
  "number_of_monthly_installments": 10,
  "collateral": 80000,
  "asset": "USDC",
  "asset_borrowed": 1,
  "asset_price": 10000,
  "loan_duration": 31622400
}
```

**Response:**

```json
{
  "message": "Loan created successfully",
  "lendingDetails": [
    {
      "loanId": "6732e5e254a8d8fa61584ecf",
      "lendersList": ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"],
      "capitalList": ["10000000000000000000000"],
      "interestList": ["50000000000000000000"],
      "totalPrincipalList": ["1050000000000000000000"],
      "receivableAmountMonthlyByLenders": [
        {
          "lend_id": "67323917b92f29485f4f09da",
          "user_id": "67322f8a7c23992197de6bce",
          "amount": 1000,
          "interest": 50,
          "total_amount": 1050,
          "remaining_amount": 10000
        }
      ],
      "totalAmount": 10000,
      "loanDuration": 31622400,
      "startDate": "2024-11-12T05:21:38.786Z",
      "endDate": "2025-11-13T05:21:38.787Z",
      "monthsNotPaid": 0,
      "upFrontAmount": 2000
    }
  ]
}
```

### 5. Interact with Contracts

With the response from the above request, the frontend can now interact directly with the contract where the user will be prompted to make a payment of 20% of the loan amount to the contract address. The contract will then take the funds from the deposit pool.

### 6. Payments

Authenticated users can make payments towards their loans.

**Endpoint:** `POST /payment`

**Request Body:**

```json
{
  "user_address": "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  "payment_amount": 1050,
  "loan_id": "6732e5e254a8d8fa61584ecf",
  "asset": "USDC"
}
```

**Response:**

```json
{
  "message": "Payment created successfully",
  "data": {
    "user_id": "6732e066f1062f9adf5181d2",
    "user_address": "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "payment_amount": 1050,
    "payment_time": 1731391936938,
    "loan_id": "6732e5e254a8d8fa61584ecf",
    "asset": "USDC",
    "lenders": [],
    "_id": "6732f1c08be7ee428fd81dcc",
    "amount_to_lenders": [],
    "__v": 0
  },
  "disbursals": {
    "paymentId": "6732f1c08be7ee428fd81dcc",
    "loanId": "6732e5e254a8d8fa61584ecf",
    "lenders": ["0x5b38da6a701c568545dcfcb03fcb875f56beddc4"],
    "amounts": ["950000000000000000000"],
    "interests": ["50000000000000000000"],
    "totalAmount": ["1000000000000000000000"]
  }
}
```

## Conclusion

In addition to the endpoints described above,Zeistal Project backend includes several other endpoints to enhance user interaction and data retrieval. These endpoints allow users to:

- Retrieve user information
- View loan details
- Access various peripheral data related to their transactions

These additional endpoints ensure that users have comprehensive access to all necessary information and functionalities to manage their interactions with the Zeistal platform effectively.

## Complexities Handled

The Zeistal Project backend handles several complexities to ensure smooth and efficient operations:

### Liquidation Factor

The backend manages the liquidation factor, which determines when a loan should be liquidated based on the collateral value and the outstanding loan amount. This ensures that the platform remains solvent and minimizes the risk of defaults.

### Loan Closing

When a loan is fully repaid, the backend handles the closing of the loan. This involves updating the loan status, releasing any collateral held, and notifying the relevant parties.

### Slashing

In cases where borrowers fail to meet their repayment obligations, the backend handles slashing. This involves penalizing the borrower by reducing their collateral and redistributing the slashed amount to the lenders.

### Payment Updates

Every payment made by a borrower triggers updates across the system. The backend ensures that each lender's share of the payment is accurately calculated and disbursed. This includes updating the remaining loan balance, recalculating interest amounts, and adjusting the payment schedule.

### Interest Calculations

The backend performs complex interest calculations for each disbursal. This ensures that lenders receive the correct amount of interest based on the terms of the loan and the payment history. These calculations are crucial for maintaining trust and transparency on the platform.

By handling these complexities, the Zeistal Project backend ensures a robust and reliable system for all users, providing a seamless experience for both lenders and borrowers.
