const express = require("express");
const client = require("prom-client");   // Prometheus client
const app = express();
const PORT = 8080;

// Create a Registry and collect default metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Default endpoint
app.get("/", (req, res) => {
  res.send("Hello World from ekdayo Sept 1 update Node.js App 🚀");
});

// Metrics endpoint for Prometheus
app.get("/metrics", async (req, res) => {
  try {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
