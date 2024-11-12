// interest rate is 5%
const express = require("express");

const { connectDB } = require("./utils/db");
const userRouter = require("./routes/userRouter");
const authRouter = require("./routes/authRouter");
const loanRouter = require("./routes/loanRouter");
const paymentRouter = require("./routes/paymentRouter");
const lendingRouter = require("./routes/lendRouter");

const { seralizeUser } = require("./controllers/authController");

const app = express();
connectDB();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(seralizeUser);

app.use("/auth", authRouter);
app.use("/user", userRouter);
app.use("/loan", loanRouter);
app.use("/payment", paymentRouter);
app.use("/lending", lendingRouter);

app.get("/", async (req, res) => {
  return res.json({ message: "Hello World" });
});

app.listen(5000, () => {
  console.log("Server started on port 5000");
});
