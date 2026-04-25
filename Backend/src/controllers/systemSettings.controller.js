import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { SystemSettings } from "../models/systemSettings.model.js";
import { StockTrade } from "../models/stocktrade.model.js";
import { Wallet } from "../models/wallet.model.js";

// Fetch or initialize System Settings
const getSettings = asyncHandler(async (req, res) => {
    let settings = await SystemSettings.findOne();
    if (!settings) {
        settings = await SystemSettings.create({ marketStatus: 'OPEN' });
    }
    return res.status(200).json(
        new ApiResponse(200, settings, "System settings fetched successfully")
    );
});

// Update Market Status (OPEN / CLOSED)
const updateMarketStatus = asyncHandler(async (req, res) => {
    const { status } = req.body;
    if (!status || !['OPEN', 'CLOSED'].includes(status)) {
        throw new ApiError(400, "Invalid market status. Must be OPEN or CLOSED.");
    }

    let settings = await SystemSettings.findOne();
    if (!settings) {
        settings = new SystemSettings({ marketStatus: status });
    } else {
        settings.marketStatus = status;
    }
    await settings.save();

    // When closing the market, rollback all pending orders
    let rolledBack = 0;
    if (status === 'CLOSED') {
        const pendingOrders = await StockTrade.find({ status: 'pending' });

        for (const order of pendingOrders) {
            // Refund locked coins for pending buy orders
            if (order.type === 'buy') {
                const refundAmount = order.quantity * order.limitPrice;
                await Wallet.findOneAndUpdate(
                    { username: order.username },
                    { $inc: { campusCoins: refundAmount, lockedCoins: -refundAmount } }
                );
            }
            // Cancel the order
            order.status = 'cancelled';
            await order.save();
            rolledBack++;
        }

        console.log(`[Market Close] Rolled back ${rolledBack} pending orders.`);
    }

    return res.status(200).json(
        new ApiResponse(200, { ...settings.toObject(), rolledBack }, `Market ${status}. ${rolledBack > 0 ? `${rolledBack} pending orders rolled back.` : ''}`)
    );
});

export {
    getSettings,
    updateMarketStatus
};
