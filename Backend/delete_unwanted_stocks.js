import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { Stock } from './src/models/stock.model.js';
import { StockTrade } from './src/models/stocktrade.model.js';
import { UserStocks } from './src/models/userstocks.model.js';
import { Wallet } from './src/models/wallet.model.js';
import { Transaction } from './src/models/transaction.model.js';
import { User } from './src/models/user.model.js';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URLI;

async function deleteSpecificStocks() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('Connected!');

        const stocksToDelete = ['101', 'AAPL'];

        for (const stockId of stocksToDelete) {
            console.log(`Processing deletion for stock: ${stockId}`);
            
            const stock = await Stock.findOne({ stockId });
            if (!stock) {
                console.log(`Stock ${stockId} not found, skipping.`);
                continue;
            }

            const { price, name } = stock;

            // 1. Find all user holdings
            const userHoldings = await UserStocks.find({ stockId, quantity: { $gt: 0 } });
            console.log(`Found ${userHoldings.length} users holding ${stockId}.`);

            // 2. Refund each user
            for (const holding of userHoldings) {
                const refundAmount = holding.quantity * price;
                console.log(`Refunding ${holding.username}: ${refundAmount} coins for ${holding.quantity} shares.`);
                
                await Wallet.findOneAndUpdate(
                    { username: holding.username },
                    { $inc: { campusCoins: refundAmount } }
                );

                const user = await User.findOne({ username: holding.username });
                if (user) {
                    await Transaction.create({
                        userId: user._id,
                        title: `Refund: ${name} deleted`,
                        amount: refundAmount,
                        isPositive: true
                    });
                }
            }

            // 3. Cleanup
            await UserStocks.deleteMany({ stockId });
            await StockTrade.deleteMany({ stockId, status: "pending" });
            
            // 4. Delete Stock
            await Stock.deleteOne({ stockId });
            console.log(`Successfully deleted stock ${stockId}.`);
        }

        console.log('Finished processing all specified stocks.');
        process.exit(0);
    } catch (error) {
        console.error('Deletion script failed:', error);
        process.exit(1);
    }
}

deleteSpecificStocks();
