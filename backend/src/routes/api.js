const express = require('express');
const router = express.Router();

const gemini = require('./controllers/gemini');
const exportController = require('./controllers/export');

router.use('/gemini', gemini);
router.use('/project', exportController);

module.exports = router;
