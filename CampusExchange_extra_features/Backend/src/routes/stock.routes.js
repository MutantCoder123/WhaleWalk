import { Router } from "express";
import { getAllStocks, getUserStocks, placeOrder, getMyOrders, getCompletedOrders, createStock } from "../controllers/stock.controller.js"
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router()

router.route("/").get(getAllStocks)
router.route("/portfolio").get(verifyJWT, getUserStocks)
router.route("/order").post(verifyJWT, placeOrder)
router.route("/orders").get(verifyJWT, getMyOrders)
router.route("/completed-orders").get(verifyJWT, getCompletedOrders)
router.route("/createstock").post(createStock)
export default router