import { Router } from "express";
import { createZone, getAllZones, deleteZone, updateZone } from "../controllers/zone.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

router.route("/").post(verifyJWT, createZone);
router.route("/").get(getAllZones); // Let anyone get zones without JWT just to be easy
router.route("/:id").delete(verifyJWT, deleteZone).patch(verifyJWT, updateZone);

export default router;
