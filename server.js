const express = require("express");
const fs = require("fs");
const path = require("path");
const app = express();

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

const DB_FILE = "./keys.json";

// Carrega ou cria o banco de keys
function loadKeys() {
  if (!fs.existsSync(DB_FILE)) fs.writeFileSync(DB_FILE, JSON.stringify([]));
  return JSON.parse(fs.readFileSync(DB_FILE, "utf-8"));
}

function saveKeys(keys) {
  fs.writeFileSync(DB_FILE, JSON.stringify(keys, null, 2));
}

// Middleware admin
function adminAuth(req, res, next) {
  const token = req.headers["x-admin-token"];
  if (token !== process.env.ADMIN_TOKEN) {
    return res.status(401).json({ error: "Não autorizado" });
  }
  next();
}

// ──────────────────────────────────────────────
// ROTA PÚBLICA — script Lua busca aqui
// Retorna apenas as keys ativas, uma por linha
// ──────────────────────────────────────────────
app.get("/keys", (req, res) => {
  const keys = loadKeys();
  const ativas = keys
    .filter(k => k.status === "active" && new Date(k.expires) > new Date())
    .map(k => k.key)
    .join("\n");

  res.setHeader("Content-Type", "text/plain");
  res.send(ativas);
});

// ──────────────────────────────────────────────
// VALIDAR KEY (verifica status, expiração, userid)
// ──────────────────────────────────────────────
app.get("/validate", (req, res) => {
  const { key, userid } = req.query;
  if (!key) return res.json({ valid: false, message: "Key não informada" });

  const keys = loadKeys();
  const k = keys.find(x => x.key === key);

  if (!k) return res.json({ valid: false, message: "Key não encontrada" });
  if (k.status === "banned") return res.json({ valid: false, message: "Key banida" });
  if (k.status === "expired" || new Date(k.expires) < new Date()) {
    return res.json({ valid: false, message: "Key expirada" });
  }

  // Vínculo de userid (1 pessoa por key)
  if (k.userid && k.userid !== userid) {
    return res.json({ valid: false, message: "Key já em uso por outro usuário" });
  }

  if (!k.userid && userid) {
    k.userid = userid;
    saveKeys(keys);
  }

  res.json({ valid: true, plan: k.plan, expires_at: k.expires, message: "OK" });
});

// ──────────────────────────────────────────────
// ADMIN — Gerar key
// ──────────────────────────────────────────────
app.post("/generate", adminAuth, (req, res) => {
  const { plan, note, lock_ip, lock_hwid } = req.body;
  const plans = { Basic: 30, Pro: 90, Ultimate: 365, Lifetime: 99999 };
  const days = plans[plan] || 30;

  const keys = loadKeys();
  const seg = () => Math.random().toString(36).substring(2, 6).toUpperCase();
  const newKey = {
    key: `VLH-${seg()}-${seg()}-${seg()}-${String(keys.length + 1).padStart(4, "0")}`,
    plan: plan || "Basic",
    status: "active",
    expires: new Date(Date.now() + days * 86400000).toISOString().split("T")[0],
    userid: "",
    ip: lock_ip || "",
    hwid: lock_hwid || "",
    note: note || "",
  };

  keys.push(newKey);
  saveKeys(keys);
  res.json({ success: true, key: newKey.key, expires: newKey.expires });
});

// ──────────────────────────────────────────────
// ADMIN — Listar keys
// ──────────────────────────────────────────────
app.get("/admin/keys", adminAuth, (req, res) => {
  res.json(loadKeys());
});

// ──────────────────────────────────────────────
// ADMIN — Banir key
// ──────────────────────────────────────────────
app.post("/ban", adminAuth, (req, res) => {
  const { key } = req.body;
  const keys = loadKeys();
  const k = keys.find(x => x.key === key);
  if (!k) return res.json({ success: false, message: "Key não encontrada" });
  k.status = "banned";
  saveKeys(keys);
  res.json({ success: true });
});

// ──────────────────────────────────────────────
// ADMIN — Resetar userid (libera key para outro usuário)
// ──────────────────────────────────────────────
app.post("/reset", adminAuth, (req, res) => {
  const { key } = req.body;
  const keys = loadKeys();
  const k = keys.find(x => x.key === key);
  if (!k) return res.json({ success: false, message: "Key não encontrada" });
  k.userid = "";
  saveKeys(keys);
  res.json({ success: true, message: "Usuário desvinculado" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Valhalla API rodando na porta ${PORT}`));
