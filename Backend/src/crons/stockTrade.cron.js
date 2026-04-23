import cron from "node-cron"
import { StockTrade } from "../models/stocktrade.model.js"
import { matchOrdersForStock } from "../utils/orderMatcher.js"

const stockTradeCron = () => {
    cron.schedule('0 0 * * *', async () => {
        console.log("Running scheduled stock trade execution sweep...")

        try {
            // get all unique stocks that have pending orders
            const pendingOrders = await StockTrade.find({ status: "pending" })
            const stockIds = [...new Set(pendingOrders.map(o => o.stockId))]

            for (const stockId of stockIds) {
                await matchOrdersForStock(stockId);
            }

            console.log("Scheduled stock trade execution done!")

        } catch (error) {
            console.log("Stock trade cron error:", error)
        }
    }, {
        timezone: "Asia/Kolkata"
    })
}

export { stockTradeCron }