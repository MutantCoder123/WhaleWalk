import cron from "node-cron"
import { StockTrade } from "../models/stocktrade.model.js"
import { Stock } from "../models/stock.model.js"
import { SystemSettings } from "../models/systemSettings.model.js"
import { matchOrdersForStock } from "../utils/orderMatcher.js"

const stockTradeCron = () => {
    // 1. Live Price Simulation (Runs every 5 seconds)
    setInterval(async () => {
        try {
            // Skip price fluctuation if market is closed
            const settings = await SystemSettings.findOne();
            if (settings && settings.marketStatus === 'CLOSED') return;

            const allStocks = await Stock.find({});
            for (const stock of allStocks) {
                // Random fluctuation between -0.25% and +0.25%
                const changePcnt = 1 + ((Math.random() - 0.5) * 0.005);
                stock.price = Math.max(0.01, stock.price * changePcnt);
                // Also match any pending orders based on this new price immediately
                await stock.save();
                await matchOrdersForStock(stock.stockId);
            }
        } catch (error) {
            console.error("Live stock simulation error:", error);
        }
    }, 5000);

    // 2. Hourly History Logging (Runs every hour on the spot)
    cron.schedule('0 * * * *', async () => {
        console.log("Running hourly history logging...");
        try {
            const allStocks = await Stock.find({});
            for (const stock of allStocks) {
                // Ensure array length isn't infinite (e.g. keep last 72 hours)
                if (stock.history.length >= 72) stock.history.shift();
                
                stock.history.push({
                    price: stock.price,
                    timestamp: new Date()
                });
                await stock.save();
            }
        } catch (error) {
            console.error("Hourly history cron error:", error);
        }
    }, {
        timezone: "Asia/Kolkata"
    });

    // 3. Daily Rollover (Runs at midnight)
    cron.schedule('0 0 * * *', async () => {
        console.log("Running daily price rollover...")

        try {
            const allStocks = await Stock.find({});
            for (const stock of allStocks) {
                
                if (stock.previousPrice > 0) {
                    stock.lastDayPercentageChange = ((stock.price - stock.previousPrice) / stock.previousPrice) * 100;
                } else {
                    stock.lastDayPercentageChange = 0;
                }
                
                stock.previousPrice = stock.price;
                await stock.save();
            }

            console.log("Daily rollover done!")

        } catch (error) {
            console.error("Stock daily cron error:", error)
        }
    }, {
        timezone: "Asia/Kolkata"
    })
}

export { stockTradeCron }