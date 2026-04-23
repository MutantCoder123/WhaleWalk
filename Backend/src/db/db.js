import mongoose from "mongoose";
import {DB_NAME} from "../constant.js";

const connectDB = async () => {
    try {
        const connectioninstance=await mongoose.connect(`${process.env.MONGODB_URLI}/${DB_NAME}`)
        console.log(`\n mongoDB connected : ${connectioninstance.connection.host}`);
    } catch (error) {
        console.log("Mongodb connection error" , error);
        process.exit(1)
    }
}

export default connectDB 