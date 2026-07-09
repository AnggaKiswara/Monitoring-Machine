const express = require('express');
const router = express.Router();
const db = require('../config/db');

// GET all factories
router.get('/', async (req, res) => {
  try {
    const [factories] = await db.query('SELECT * FROM factory ORDER BY id_factory');
    res.json({
      success: true,
      data: factories
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// GET factory by ID
router.get('/:id', async (req, res) => {
  try {
    const [factories] = await db.query('SELECT * FROM factory WHERE id_factory = ?', [req.params.id]);
    if (factories.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Factory not found'
      });
    }
    res.json({
      success: true,
      data: factories[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// POST create factory
router.post('/', async (req, res) => {
  try {
    const { nama_factory, lokasi_factory, health_factory } = req.body;
    const [result] = await db.query(
      'INSERT INTO factory (nama_factory, lokasi_factory, health_factory) VALUES (?, ?, ?)',
      [nama_factory, lokasi_factory, health_factory || 0]
    );
    res.status(201).json({
      success: true,
      data: {
        id_factory: result.insertId,
        nama_factory,
        lokasi_factory,
        health_factory: health_factory || 0
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// PUT update factory
router.put('/:id', async (req, res) => {
  try {
    const { nama_factory, lokasi_factory, health_factory } = req.body;
    const [checkFactory] = await db.query('SELECT * FROM factory WHERE id_factory = ?', [req.params.id]);
    if (checkFactory.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Factory not found'
      });
    }
    const [result] = await db.query(
      'UPDATE factory SET nama_factory = ?, lokasi_factory = ?, health_factory = ? WHERE id_factory = ?',
      [nama_factory || checkFactory[0].nama_factory, lokasi_factory || checkFactory[0].lokasi_factory, health_factory !== undefined ? health_factory : checkFactory[0].health_factory, req.params.id]
    );
    res.json({
      success: true,
      message: 'Factory updated successfully',
      data: {
        id_factory: req.params.id,
        nama_factory: nama_factory || checkFactory[0].nama_factory,
        lokasi_factory: lokasi_factory || checkFactory[0].lokasi_factory,
        health_factory: health_factory !== undefined ? health_factory : checkFactory[0].health_factory
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// DELETE factory
router.delete('/:id', async (req, res) => {
  try {
    const [checkFactory] = await db.query('SELECT * FROM factory WHERE id_factory = ?', [req.params.id]);
    if (checkFactory.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Factory not found'
      });
    }
    const [result] = await db.query('DELETE FROM factory WHERE id_factory = ?', [req.params.id]);
    res.json({
      success: true,
      message: 'Factory deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;