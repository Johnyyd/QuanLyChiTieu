const express = require('express');
const sql = require('mssql/msnodesqlv8');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Cấu hình kết nối SQL Server
const config = {
  server: '(localdb)\\MSSQLLocalDB',
  database: 'QuanLyChiTieuDB',
  driver: 'msnodesqlv8',
  options: {
    trustedConnection: true
  }
};

// Khởi tạo kết nối Pool
const poolPromise = new sql.ConnectionPool(config)
  .connect()
  .then(pool => {
    console.log('Connected to MSSQL');
    return pool;
  })
  .catch(err => console.log('Database Connection Failed! Bad Config: ', err));

// API: Truy vấn dữ liệu (SELECT)
app.post('/query', async (req, res) => {
  try {
    const { query } = req.body;
    if (!query) return res.status(400).json({ error: 'Missing query' });

    const pool = await poolPromise;
    const result = await pool.request().query(query);
    
    res.json(result.recordset);
  } catch (err) {
    console.error('Error in /query:', err);
    res.status(500).json({ error: err.message });
  }
});

// API: Thay đổi dữ liệu (INSERT, UPDATE, DELETE)
app.post('/execute', async (req, res) => {
  try {
    const { query, params } = req.body;
    if (!query) return res.status(400).json({ error: 'Missing query' });

    const pool = await poolPromise;
    const request = pool.request();

    // Nạp các tham số vào Request để tránh SQL Injection
    if (params && typeof params === 'object') {
      for (const [key, value] of Object.entries(params)) {
        request.input(key, value);
      }
    }

    const result = await request.query(query);
    res.json({ success: true, rowsAffected: result.rowsAffected });
  } catch (err) {
    console.error('Error in /execute:', err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend API Server is running on http://0.0.0.0:${PORT}`);
});
