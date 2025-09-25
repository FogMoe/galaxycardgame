import express from "express";
import { nanoid } from "nanoid";

const PORT = Number(process.env.PORT ?? 3080);
const TTL_MS = Number(process.env.ROOM_TTL_MS ?? 5 * 60 * 1000);
const CLEANUP_INTERVAL_MS = Number(process.env.CLEANUP_INTERVAL_MS ?? 60 * 1000);

const app = express();
const rooms = new Map();

app.use(express.urlencoded({ extended: false }));
app.use((req, _res, next) => {
  req.receivedAt = Date.now();
  next();
});

app.get("/rooms/list", (_req, res) => {
  prune();
  const lines = [];
  for (const room of rooms.values()) {
    lines.push(`${room.name}|${room.host}|${room.port}|${room.note}`);
  }
  res.type("text/plain").send(lines.join("\n"));
});

app.post("/rooms/register", (req, res) => {
  const name = sanitize(req.body.name);
  const host = sanitize(req.body.host);
  const port = sanitize(req.body.port);
  const note = sanitize(req.body.note ?? "");

  if (!name || !host || !port) {
    return res.status(400).type("text/plain").send("ERR missing-field\n");
  }

  const id = nanoid();
  rooms.set(id, {
    id,
    name,
    host,
    port,
    note,
    updatedAt: req.receivedAt,
  });
  res.type("text/plain").send(`OK ${id}\n`);
});

app.post("/rooms/heartbeat", (req, res) => {
  const id = sanitize(req.body.id);
  if (!id) {
    return res.status(400).type("text/plain").send("ERR missing-id\n");
  }
  const room = rooms.get(id);
  if (!room) {
    return res.status(404).type("text/plain").send("ERR not-found\n");
  }
  room.updatedAt = req.receivedAt;
  res.type("text/plain").send("OK\n");
});

app.post("/rooms/unregister", (req, res) => {
  const id = sanitize(req.body.id);
  if (!id) {
    return res.status(400).type("text/plain").send("ERR missing-id\n");
  }
  rooms.delete(id);
  res.type("text/plain").send("OK\n");
});

function sanitize(value) {
  if (typeof value !== "string") return "";
  return value.replace(/[\r\n]/g, "").trim();
}

function prune() {
  const now = Date.now();
  for (const [id, room] of rooms) {
    if (now - room.updatedAt > TTL_MS) {
      rooms.delete(id);
    }
  }
}

setInterval(prune, CLEANUP_INTERVAL_MS).unref();

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Room list server listening on ${PORT}`);
});
