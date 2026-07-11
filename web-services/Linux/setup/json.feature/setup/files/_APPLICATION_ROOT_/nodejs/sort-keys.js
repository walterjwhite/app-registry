#!/usr/bin/env node
"use strict";
const fs = require("fs");
function sortKeysDeep(input) {
  if (Array.isArray(input)) return input.map(sortKeysDeep);
  if (input && typeof input === "object") {
    return Object.keys(input)
      .sort()
      .reduce((acc, k) => {
        acc[k] = sortKeysDeep(input[k]);
        return acc;
      }, {});
  }
  return input;
}
const filePath = process.argv[2];
function formatAndPrint(raw) {
  const json = JSON.parse(raw);
  const sorted = sortKeysDeep(json);
  const out = JSON.stringify(sorted, null, 2) + "\n";
  if (filePath) fs.writeFileSync(filePath, out, "utf8");
  else process.stdout.write(out);
}
if (filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  formatAndPrint(raw);
} else {
  let raw = "";
  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => (raw += chunk));
  process.stdin.on("end", () => formatAndPrint(raw));
}
