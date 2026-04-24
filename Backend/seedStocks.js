import mongoose from "mongoose";
import dotenv from "dotenv";
import { Stock } from "./src/models/stock.model.js";

dotenv.config();

const dummyNames = [
    "Aryabhatta", "C.V.R", "NJACK", "Gymkhana", 
    "Library", "MoodBoard", "STC", "HOUSCA", 
    "ASIMA", "BUS", "MESS-05", "MESS-04"
];

const generateHistory = (currentPrice, trendDown) => {
    const history = [];
    // If it should have a negative return, start it higher. If positive return, start it lower.
    let price = trendDown ? currentPrice * 1.2 : currentPrice * 0.8; 
    
    // Generate 72 hours of dummy data
    for (let i = 72; i >= 0; i--) {
        history.push({
            price: price,
            timestamp: new Date(Date.now() - i * 60 * 60 * 1000)
        });
        
        // Random walk towards the target `currentPrice`
        let divergence = (currentPrice - price) / (i + 1); 
        // add noise
        let noise = (Math.random() - 0.5) * (currentPrice * 0.05); 
        
        price = price + divergence + noise; 
        if (price < 0.1) price = 0.1;
    }
    // Set exact
    history[history.length - 1].price = currentPrice;
    return history;
};

const seedDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URLI);
        console.log("Connected to MongoDB for seeding.");

        await Stock.deleteMany({});
        console.log("Cleared existing stocks.");

        for (let i = 0; i < dummyNames.length; i++) {
            const name = dummyNames[i];
            const stockId = name.toUpperCase().replace(/[^A-Z0-9]/g, '');
            
            // Generate base price 50 to 500
            const currentPrice = 50 + Math.random() * 450;
            
            // Randomly assign negative trend to ~40% of the stocks
            const isNegative = Math.random() > 0.6;
            
            const prevPrice = isNegative ? currentPrice * 1.05 : currentPrice * 0.95;
            const pctChange = ((currentPrice - prevPrice) / prevPrice) * 100;
            
            const stock = new Stock({
                stockId: stockId,
                name: name,
                price: currentPrice,
                previousPrice: prevPrice,
                lastDayPercentageChange: pctChange,
                sharesct: 10000,
                history: generateHistory(currentPrice, isNegative)
            });
            await stock.save();
            console.log(`Seeded ${stockId} (${isNegative ? 'Down' : 'Up'})`);
        }

        console.log("Seeding complete.");
        process.exit(0);
    } catch (err) {
        console.error("Seeding error:", err);
        process.exit(1);
    }
};

seedDB();
