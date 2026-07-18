const express = require("express");
const router = express.Router();
const db = require("../config/db");

// GET all factories
router.get("/", async (req, res) => {
  try {
    const [factories] = await db.query("SELECT * FROM factory ORDER BY id_factory");
    res.json({ success: true, data: factories });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET factory by ID
router.get("/:id", async (req, res) => {
  try {
    const [factories] = await db.query("SELECT * FROM factory WHERE id_factory = ?", [req.params.id]);
    if (factories.length === 0) {
      return res.status(404).json({ success: false, message: "Factory not found" });
    }
    res.json({ success: true, data: factories[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST create factory
router.post("/", async (req, res) => {
  try {
    const { nama_factory, lokasi_factory, health_factory } = req.body;
    const [result] = await db.query("INSERT INTO factory (nama_factory, lokasi_factory, health_factory) VALUES (?, ?, ?)", [
      nama_factory,
      lokasi_factory,
      health_factory || 0,
    ]);
    res.status(201).json({
      success: true,
      data: {
        id_factory: result.insertId,
        nama_factory,
        lokasi_factory,
        health_factory: health_factory || 0,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// PUT update factory
router.put("/:id", async (req, res) => {
  try {
    const { nama_factory, lokasi_factory, health_factory } = req.body;
    const [checkFactory] = await db.query("SELECT * FROM factory WHERE id_factory = ?", [req.params.id]);
    if (checkFactory.length === 0) {
      return res.status(404).json({ success: false, message: "Factory not found" });
    }
    const [result] = await db.query("UPDATE factory SET nama_factory = ?, lokasi_factory = ?, health_factory = ? WHERE id_factory = ?", [
      nama_factory || checkFactory[0].nama_factory,
      lokasi_factory || checkFactory[0].lokasi_factory,
      health_factory !== undefined ? health_factory : checkFactory[0].health_factory,
      req.params.id,
    ]);
    res.json({ success: true, message: "Factory updated successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// DELETE factory (cascade: hapus station + machine miliknya dulu)
router.delete("/:id", async (req, res) => {
  try {
    const factoryId = req.params.id;
    const [checkFactory] = await db.query(
      "SELECT * FROM factory WHERE id_factory = ?",
      [factoryId],
    );
    if (checkFactory.length === 0) {
      return res.status(404).json({ success: false, message: "Factory not found" });
    }
    // Ambil station milik factory
    const [stations] = await db.query(
      "SELECT id_station FROM station WHERE id_factory = ?",
      [factoryId],
    );
    for (const st of stations) {
      // Hapus machine di station ini
      await db.query("DELETE FROM machine WHERE id_station = ?", [st.id_station]);
    }
    // Hapus station
    await db.query("DELETE FROM station WHERE id_factory = ?", [factoryId]);
    // Hapus factory
    await db.query("DELETE FROM factory WHERE id_factory = ?", [factoryId]);
    res.json({ success: true, message: "Factory deleted successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
