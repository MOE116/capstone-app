const express = require("express");
const app = express();
const PORT = 8080;

app.get("/", (req, res) => {
  res.send("Hello World from  ekd1 Node.js App 🚀");
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
