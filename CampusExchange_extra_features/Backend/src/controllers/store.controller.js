import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { StoreItem } from "../models/store.model.js";
import { User } from "../models/user.model.js";
import { Wallet } from "../models/wallet.model.js";

const getStoreItems = asyncHandler(async (req, res) => {
    const items = await StoreItem.find({ isActive: true, isPurchasable: true });
    
    return res.status(200).json(
        new ApiResponse(200, items, "Store items fetched successfully")
    );
});

const buyItem = asyncHandler(async (req, res) => {
    const { itemId } = req.params;
    const userId = req.user._id;
    const username = req.user.username;

    const item = await StoreItem.findById(itemId);
    if (!item || !item.isActive) {
        throw new ApiError(404, "Item not found or unavailable");
    }

    const user = await User.findById(userId);
    if (!user) {
        throw new ApiError(404, "User not found");
    }

    if (user.inventory.includes(itemId)) {
        throw new ApiError(400, "You already own this item");
    }

    const wallet = await Wallet.findOne({ username });
    if (!wallet) {
        throw new ApiError(404, "Wallet not found");
    }

    if (wallet.campusCoins < item.price) {
        throw new ApiError(400, "Insufficient campus coins");
    }

    // Deduct coins and add to inventory
    wallet.campusCoins -= item.price;
    await wallet.save();

    await user.addToInventory(item._id);

    return res.status(200).json(
        new ApiResponse(200, {
            item,
            newBalance: wallet.campusCoins
        }, "Item purchased successfully")
    );
});

const equipItem = asyncHandler(async (req, res) => {
    const { itemId } = req.params;
    const userId = req.user._id;

    const item = await StoreItem.findById(itemId);
    if (!item) {
        throw new ApiError(404, "Item not found");
    }

    const user = await User.findById(userId);
    if (!user) {
        throw new ApiError(404, "User not found");
    }

    if (!user.inventory.includes(itemId)) {
        throw new ApiError(400, "You do not own this item");
    }

    if (item.category === 'badge') {
        await user.updateActiveBadge(item._id);
    } else if (item.category === 'title') {
        await user.updateActiveTitle(item._id);
    } else {
        throw new ApiError(400, "Item cannot be equipped as badge or title");
    }

    return res.status(200).json(
        new ApiResponse(200, user, "Item equipped successfully")
    );
});

export {
    getStoreItems,
    buyItem,
    equipItem
};
