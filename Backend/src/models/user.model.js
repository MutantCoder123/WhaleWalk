import mongoose, { Schema } from "mongoose";
import jwt from "jsonwebtoken";
import bcryptjs from "bcryptjs";

const userSchema = new Schema(
    {
        username: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true,
            index: true,
        },
        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true,
        },
        fullName: {
            type: String,
            required: true,
            trim: true,
            index: true,
        },
        college: {
            type: String,
        },
        password: {
            type: String,
            required: [true, "Password is required"],
        },
        refreshToken: {
            type: String,
        },
        inventory: [
            {
                type: Schema.Types.ObjectId,
                ref: "StoreItem",
            }
        ],
        activeBadge: {
            type: Schema.Types.ObjectId,
            ref: "StoreItem",
        },
        activeTitle: {
            type: Schema.Types.ObjectId,
            ref: "StoreItem",
        },
        unlockedAchievements: [
            {
                type: Schema.Types.ObjectId,
                ref: "Achievement",
            }
        ],
        newlyUnlockedAchievements: [
            {
                type: Schema.Types.ObjectId,
                ref: "Achievement",
            }
        ],
    },
    {
        timestamps: true,
    }
);

userSchema.pre("save", async function (next) {
    if(!this.isModified("password")) return;

    this.password = await bcryptjs.hash(this.password, 10)
})

userSchema.methods.isPasswordCorrect = async function(password){
    return await bcryptjs.compare(password, this.password)
}

userSchema.methods.generateAccessToken = function(){
    return jwt.sign(
        {
            _id: this._id,
            email: this.email,
            username: this.username,
            fullName: this.fullName
        },
        process.env.ACCESS_TOKEN_SECRET,
        {
            expiresIn: process.env.ACCESS_TOKEN_EXPIRY
        }
    )
}

userSchema.methods.generateRefreshToken = function(){
    return jwt.sign(
        {
            _id: this._id,
            
        },
        process.env.REFRESH_TOKEN_SECRET,
        {
            expiresIn: process.env.REFRESH_TOKEN_EXPIRY
        }
    )
}

userSchema.methods.updateActiveBadge = async function(badgeId){
    this.activeBadge = badgeId;
    await this.save({ validateBeforeSave: false });
    return this;
}

userSchema.methods.updateActiveTitle = async function(titleId){
    this.activeTitle = titleId;
    await this.save({ validateBeforeSave: false });
    return this;
}

userSchema.methods.addToInventory = async function(itemId){
    if(!this.inventory.includes(itemId)){
        this.inventory.push(itemId);
        await this.save({ validateBeforeSave: false });
    }
    return this;
}

userSchema.methods.unlockAchievement = async function(achievementId){
    if(!this.unlockedAchievements.includes(achievementId)){
        this.unlockedAchievements.push(achievementId);
        this.newlyUnlockedAchievements.push(achievementId);
        await this.save({ validateBeforeSave: false });
        return true;
    }
    return false;
}

export const User = mongoose.model("User", userSchema);