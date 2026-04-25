import { Router } from "express";
import { getSettings, updateMarketStatus } from "../controllers/systemSettings.controller.js";

const router = Router();

// Assuming admin token is checked wherever these are used, or user auth.
// Depending on architecture, we might want verifyJWT middleware here.
// For now, attaching the routes directly.
router.route("/settings").get(getSettings);
router.route("/settings/market-status").post(updateMarketStatus);

export default router;
