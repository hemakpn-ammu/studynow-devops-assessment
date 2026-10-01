const test = require("node:test");
const assert = require("node:assert");

test("application configuration test", () => {
  const port = process.env.PORT || 3000;

  assert.strictEqual(port, 3000);
});