import mongoose, { Schema } from "mongoose";

const storeSchema = new Schema(
    {
        name: {
            type: String,
            required: true,
            unique: true,
            trim: true,
        },
        description: {
            type: String,
            required: true,
        },
        price: {
            type: Number,
            required: true,
            min: [0, "Price cannot be negative"],
        },
        category: {
            type: String,
            enum: ['badge', 'title', 'theme'],
            required: true,
        },
        imageUrl: {
            type: String, 
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        isPurchasable: {
            type: Boolean,
            default: true,
        }
    },
    {
        timestamps: true,
    }
);

export const StoreItem = mongoose.model("StoreItem", storeSchema);
