import { Router } from "express";
import { getStoreItems, buyItem, equipItem } from "../controllers/store.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

router.use(verifyJWT);

router.route("/items").get(getStoreItems);
router.route("/buy/:itemId").post(buyItem);
router.route("/equip/:itemId").post(equipItem);

export default router;
