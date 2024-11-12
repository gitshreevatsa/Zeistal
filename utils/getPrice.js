// write a function to get rate of cBTC <-> USDT

const axios = require("axios");

const url = "https://priceserver-qrwzxck8.b4a.run/coins/price-convert?amount=1&symbol=BTC&convert=USD"
const getRate = async() => {
    try {
        const response = await axios.get(url);
        console.log(response.data.convertedPrice);
        return response.data.convertedPrice;
    } catch (error) {
        console.error(error.message);
    }
}


module.exports = { getRate };