const http = require('http');
const { calculateFee, validatePayment } = require('./payments');

const PORT = process.env.PORT || 3001;
const NODE_ENV = process.env.NODE_ENV || 'development';
const VERSION = require('../package.json').version;

const server = http.createServer((req, res) => {
  if (req.url === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      version: VERSION,
      environment: NODE_ENV,
      port: PORT
    }));
  } else if (req.url === '/fee' && req.method === 'GET') {
    const fee = calculateFee(100);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ fee }));
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

server.listen(PORT, () => {
  console.log(`kk-payments v${VERSION} running on port ${PORT} in ${NODE_ENV} mode`);
});
