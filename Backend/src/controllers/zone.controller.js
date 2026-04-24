import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Zone } from "../models/zone.model.js";

const createZone = asyncHandler(async (req, res) => {
    const { name, latitude, longitude, radiusMeters } = req.body;

    if (!name || latitude === undefined || longitude === undefined) {
        throw new ApiError(400, "Name, latitude, and longitude are required.");
    }

    const existingZone = await Zone.findOne({ name });
    if (existingZone) {
        throw new ApiError(409, "A zone with this name already exists.");
    }

    const newZone = await Zone.create({
        name,
        latitude,
        longitude,
        radiusMeters: radiusMeters || 50.0
    });

    return res.status(201).json(new ApiResponse(201, newZone, "Zone created successfully"));
});

const getAllZones = asyncHandler(async (req, res) => {
    const zones = await Zone.find({});
    return res.status(200).json(new ApiResponse(200, zones, "Zones fetched successfully"));
});

const deleteZone = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const zone = await Zone.findByIdAndDelete(id);

    if (!zone) {
        throw new ApiError(404, "Zone not found");
    }

    return res.status(200).json(new ApiResponse(200, zone, "Zone deleted successfully"));
});

const updateZone = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { name, latitude, longitude, radiusMeters } = req.body;

    const zone = await Zone.findByIdAndUpdate(
        id,
        {
            $set: {
                name,
                latitude,
                longitude,
                radiusMeters
            }
        },
        { new: true }
    );

    if (!zone) {
        throw new ApiError(404, "Zone not found");
    }

    return res.status(200).json(new ApiResponse(200, zone, "Zone updated successfully"));
});

export { createZone, getAllZones, deleteZone, updateZone };
