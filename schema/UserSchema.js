const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  user_address: { type: String, required: true },
  totalCapitalLent: { type: Number, default: 0 },
  totalCapitalBorrowed: { type: Number, default: 0 },
  totalInterestEarned: { type: Number, default: 0 },
  totalReturns: { type: Number, default: 0 },
  loans: [{ type: mongoose.Types.ObjectId, ref: "Loan" }],
  investments: [
    {
      loan_id: { type: mongoose.Types.ObjectId, ref: "Loan" },
      amount: { type: Number },
      interest: { type: Number },
      total: { type: Number },
      received: { type: Number, default: 0 },
      interestReceived: { type: Number, default: 0 },
      totalReceived: { type: Number, default: 0 },
    },
  ],
  returns: [
    {
      loan_id: { type: mongoose.Types.ObjectId, ref: "Loan" },
      amount: { type: Number },
    },
  ],
  lendings: [{ type: mongoose.Types.ObjectId, ref: "Lend" }],
  payments: [{ type: mongoose.Types.ObjectId, ref: "Payment" }],
  withdraws: [{ type: mongoose.Types.ObjectId, ref: "Withdraw" }],
});

const User = mongoose.model("User", UserSchema);

module.exports = User;
