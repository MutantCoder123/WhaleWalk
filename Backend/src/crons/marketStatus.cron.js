import cron from "node-cron";
import { SystemSettings } from "../models/systemSettings.model.js";
import { StockTrade } from "../models/stocktrade.model.js";
import { Wallet } from "../models/wallet.model.js";

function marketStatusCron() {
    // Open Market at 9:15 AM Monday to Saturday
    cron.schedule('15 9 * * 1-6', async () => {
        try {
            console.log("[Cron] Automatically opening market at 9:15 AM");
            let settings = await SystemSettings.findOne();
            if (!settings) settings = new SystemSettings();
            
            settings.marketStatus = 'OPEN';
            await settings.save();
            console.log("[Cron] Market is now OPEN");
        } catch (error) {
            console.error("[Cron] Failed to open market:", error);
        }
    }, { timezone: "Asia/Kolkata" });

    // Close Market at 3:30 PM (15:30) Monday to Saturday
    cron.schedule('30 15 * * 1-6', async () => {
        try {
            console.log("[Cron] Automatically closing market at 3:30 PM");
            let settings = await SystemSettings.findOne();
            if (!settings) settings = new SystemSettings();
            
            settings.marketStatus = 'CLOSED';
            await settings.save();

            // Rollback all pending orders
            const pendingOrders = await StockTrade.find({ status: 'pending' });
            let rolledBack = 0;

            for (const order of pendingOrders) {
                if (order.type === 'buy') {
                    const refundAmount = order.quantity * order.limitPrice;
                    await Wallet.findOneAndUpdate(
                        { username: order.username },
                        { $inc: { campusCoins: refundAmount, lockedCoins: -refundAmount } }
                    );
                }
                order.status = 'cancelled';
                await order.save();
                rolledBack++;
            }

            console.log(`[Cron] Market is now CLOSED. Rolled back ${rolledBack} pending orders.`);
        } catch (error) {
            console.error("[Cron] Failed to close market:", error);
        }
    }, { timezone: "Asia/Kolkata" });

    console.log("⌚ Market Status Cron: Open at 09:15, Close at 15:30 (Mon-Sat, IST)");
}

export { marketStatusCron };
