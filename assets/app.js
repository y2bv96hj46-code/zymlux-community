import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/* ============================================================
   Helpers
============================================================ */
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
const cfg = window.ZYMLUX_CONFIG || {};
let toastTimer;
function toast(msg) {
  const t = $("#toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove("show"), 2600);
}
function fmtTime(iso) {
  const d = new Date(iso);
  return d.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });
}
function colorFromString(str) {
  let h = 0;
  for (let i = 0; i < (str || "").length; i++) h = (h * 31 + str.charCodeAt(i)) % 360;
  return `hsl(${h} 55% 64%)`;
}
function avatarGrad(id) {
  let h = 0;
  for (let i = 0; i < (id || "").length; i++) h = (h * 31 + id.charCodeAt(i)) % 360;
  const h2 = (h + 45) % 360;
  return `linear-gradient(135deg, hsl(${h} 62% 60%), hsl(${h2} 58% 46%))`;
}
function safeImageUrl(url) {
  // N'accepte qu'une URL https propre (anti-injection CSS dans background-image)
  try {
    const u = new URL(url, location.origin);
    if (u.protocol !== "https:" && u.protocol !== "http:") return null;
    return u.href.replace(/["'()\\]/g, encodeURIComponent);
  } catch (e) { return null; }
}
function applyAvatar(el, name, id, url, level) {
  if (!el) return;
  el.classList.add("avatar");
  const safe = url ? safeImageUrl(url) : null;
  if (safe) {
    el.style.backgroundImage = `url("${safe}")`;
    el.style.backgroundSize = "cover";
    el.style.backgroundPosition = "center";
    el.textContent = "";
  } else {
    el.style.backgroundImage = "none";
    el.style.background = avatarGrad(id);
    el.textContent = (name ? [...name][0] || "?" : "?").toUpperCase();
  }
  if (level != null && typeof FRAME_TIERS !== "undefined") {
    ALL_FRAME_CLS.forEach((c) => el.classList.remove(c));
    el.classList.add(frameClassForLevel(level));
  }
}
function refreshMyAvatars() {
  applyAvatar($("#me-av"), state.profile.pseudo, state.user.id, state.profile.avatar_url);
  applyAvatar($("#dash-av"), state.profile.pseudo, state.user.id, state.profile.avatar_url);
  applyAvatar($("#pf-av"), state.profile.pseudo, state.user.id, state.profile.avatar_url);
  if (typeof applyHalo === "function") applyHalo();
}
function observeReveals() {
  const els = $$(".reveal");
  if (!("IntersectionObserver" in window)) { els.forEach((e) => e.classList.add("is-visible")); return; }
  const o = new IntersectionObserver((entries) => {
    entries.forEach((e) => { if (e.isIntersecting) { e.target.classList.add("is-visible"); o.unobserve(e.target); } });
  }, { threshold: 0.12 });
  els.forEach((e) => o.observe(e));
}

/* ---------- Icônes SVG (remplacent les emojis décoratifs) ---------- */
const _svg = (p) => `<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${p}</svg>`;
const ICONS = {
  compass: _svg('<circle cx="12" cy="12" r="9"/><polygon points="15.5 8.5 13.5 13.5 8.5 15.5 10.5 10.5"/>'),
  chart:   _svg('<path d="M4 4v16h16"/><path d="M8 14l3-3 3 2 4-6"/>'),
  wind:    _svg('<path d="M4 9h9a2.5 2.5 0 1 0-2.5-2.5"/><path d="M4 13h12a2.5 2.5 0 1 1-2.5 2.5"/><path d="M4 17h6"/>'),
  leaf:    _svg('<path d="M5 19c8 0 14-4 14-13 0 0-13-2-13 8 0 1 .3 3 2 5"/><path d="M5 19c3-5 6-7 10-9"/>'),
  award:   _svg('<circle cx="12" cy="9" r="5"/><path d="M9 13l-1.5 8L12 18l4.5 3L15 13"/>'),
  flame:   _svg('<path d="M12 3c.5 3 4 4 4 8a4 4 0 0 1-8 0c0-1.5.5-2.5 1.5-3.5 0 1.5 1 2.5 2.5 2.5C12 8 11 6.5 12 3Z"/>'),
  door:    _svg('<path d="M4 21h16"/><path d="M6 21V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v16"/><circle cx="13.5" cy="12" r=".7" fill="currentColor" stroke="none"/>'),
  moon:    _svg('<path d="M21 12.5A8.5 8.5 0 1 1 11.5 3 6.5 6.5 0 0 0 21 12.5Z"/>'),
  droplet: _svg('<path d="M12 3s6 5.5 6 10a6 6 0 0 1-12 0c0-4.5 6-10 6-10Z"/>'),
  star:    _svg('<path d="M12 3l2.4 5.6L20 9.3l-4 3.9 1 5.8L12 16.8 7 19l1-5.8-4-3.9 5.6-.7Z"/>'),
  heart:   _svg('<path d="M20.8 5.6a5 5 0 0 0-7.1 0L12 7.3l-1.7-1.7a5 5 0 1 0-7.1 7.1L12 21l8.8-8.3a5 5 0 0 0 0-7.1Z"/>'),
  message: _svg('<path d="M21 11.5a8.4 8.4 0 0 1-12.4 7.4L3 21l2.1-5.6A8.4 8.4 0 1 1 21 11.5Z"/>'),
};
const icon = (n) => ICONS[n] || ICONS.message;
const roomIcon = (slug) => ({ accueil: ICONS.door, nuit: ICONS.moon, anxiete: ICONS.droplet, victoires: ICONS.star, entraide: ICONS.heart }[slug] || ICONS.message);
const QUOTES = [
  "Respire. Tu as déjà survécu à 100 % de tes pires journées.",
  "Tu n'as pas besoin d'aller bien pour avoir ta place ici.",
  "Un petit pas reste un pas. Et tu avances.",
  "La nuit finit toujours par s'éclaircir.",
  "Ce que tu ressens est réel, et tu as le droit de le déposer ici.",
  "Demander de l'aide, c'est du courage, jamais une faiblesse.",
  "Tu vaux plus que ta pire pensée d'aujourd'hui.",
];
function setQuote() {
  const day = Math.floor(Date.now() / 86400000);
  $("#quote-day").textContent = "« " + QUOTES[day % QUOTES.length] + " »";
}

/* ============================================================
   Vérification de la configuration
============================================================ */
const configured =
  cfg.SUPABASE_URL &&
  cfg.SUPABASE_ANON_KEY &&
  !cfg.SUPABASE_URL.includes("VOTRE-PROJET") &&
  !cfg.SUPABASE_ANON_KEY.includes("VOTRE_CLE");

if (!configured) {
  $("#loading").style.display = "none";
  $("#setup").style.display = "flex";
  throw new Error("Zymlux: configuration Supabase manquante (assets/config.js).");
}

const sb = createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);

/* ============================================================
   État
============================================================ */
const state = {
  user: null,
  profile: null,
  rooms: [],
  currentRoom: null,
  roomChannel: null,
  moodChannel: null,
  challenge: null,
  selectedMood: null,
};

/* ============================================================
   Démarrage / aiguillage session
============================================================ */
(async function boot() {
  const { data } = await sb.auth.getSession();
  $("#loading").style.display = "none";
  if (data.session) {
    await enterApp(data.session.user);
  } else {
    $("#auth").style.display = "flex";
    if (new URLSearchParams(location.search).has("signup")) $("#tab-signup").click();
  }
  sb.auth.onAuthStateChange((evt) => {
    if (evt === "SIGNED_OUT") location.href = "index.html";
  });
})();

/* ============================================================
   AUTH (onglets + connexion + inscription)
============================================================ */
const authMsg = $("#auth-msg");
function setAuthMsg(text, kind) {
  authMsg.textContent = text || "";
  authMsg.className = "auth-msg" + (kind ? " " + kind : "");
}
$("#tab-login").addEventListener("click", () => {
  $("#tab-login").classList.add("active");
  $("#tab-signup").classList.remove("active");
  $("#form-login").style.display = "flex";
  $("#form-signup").style.display = "none";
  setAuthMsg("");
});
$("#tab-signup").addEventListener("click", () => {
  $("#tab-signup").classList.add("active");
  $("#tab-login").classList.remove("active");
  $("#form-signup").style.display = "flex";
  $("#form-login").style.display = "none";
  setAuthMsg("");
});

$("#form-login").addEventListener("submit", async (e) => {
  e.preventDefault();
  const btn = e.target.querySelector("button");
  btn.disabled = true;
  setAuthMsg("Connexion…");
  const { error } = await sb.auth.signInWithPassword({
    email: $("#li-email").value.trim(),
    password: $("#li-pass").value,
  });
  btn.disabled = false;
  if (error) return setAuthMsg(traduireErreur(error.message), "err");
  const { data } = await sb.auth.getUser();
  if (data.user) enterApp(data.user);
});

$("#form-signup").addEventListener("submit", async (e) => {
  e.preventDefault();
  const btn = e.target.querySelector("button");
  const pseudo = $("#su-pseudo").value.trim() || "Membre";
  const pass = $("#su-pass").value;
  if (pass.length < 6) return setAuthMsg("Le mot de passe doit faire au moins 6 caractères.", "err");
  btn.disabled = true;
  setAuthMsg("Création du compte…");
  const { data, error } = await sb.auth.signUp({
    email: $("#su-email").value.trim(),
    password: pass,
    options: { data: { pseudo, is_anonymous: $("#su-anon").checked } },
  });
  btn.disabled = false;
  if (error) return setAuthMsg(traduireErreur(error.message), "err");
  if (data.session && data.user) {
    enterApp(data.user);
  } else {
    setAuthMsg("Compte créé ! Vérifie tes e-mails pour confirmer, puis connecte-toi.", "ok");
    $("#tab-login").click();
  }
});

function traduireErreur(m) {
  m = (m || "").toLowerCase();
  if (m.includes("invalid login")) return "E-mail ou mot de passe incorrect.";
  if (m.includes("already registered") || m.includes("already been registered")) return "Cet e-mail a déjà un compte.";
  if (m.includes("email")) return "Adresse e-mail invalide.";
  if (m.includes("password")) return "Mot de passe trop court (6 caractères min).";
  return "Une erreur est survenue. Réessaie.";
}

/* ============================================================
   Entrée dans l'application
============================================================ */
async function enterApp(user) {
  state.user = user;
  // Profil (avec petite tolérance si le trigger n'a pas encore tourné)
  let profile = await fetchProfile(user.id);
  if (!profile) {
    await new Promise((r) => setTimeout(r, 800));
    profile = await fetchProfile(user.id);
  }
  state.profile = profile || { pseudo: "Membre", is_anonymous: true, avatar_emoji: "🌙" };
  state.isAdmin = !!state.profile.is_admin;

  if (state.profile.is_banned) { showBanned(); return; }

  $("#auth").style.display = "none";
  $("#app").style.display = "flex";

  $("#me-name").textContent = state.profile.pseudo;
  applyAvatar($("#me-av"), state.profile.pseudo, state.user.id, state.profile.avatar_url);

  if (state.isAdmin) { const c = $("#admin-card"); if (c) c.style.display = ""; }

  initNav();
  await initChat();
  initFeed();
  initDM();
  await initDashboard();
  initProfile();
  observeReveals();
  loadLevel();
  if (state.isAdmin) loadAdmin();
}

async function fetchProfile(id) {
  const { data } = await sb.from("profiles").select("*").eq("id", id).maybeSingle();
  return data;
}

/* ============================================================
   Navigation entre vues
============================================================ */
function switchView(v) {
  $$("[data-view]").forEach((x) => x.classList.toggle("active", x.dataset.view === v));
  $$(".view").forEach((vw) => vw.classList.remove("active"));
  const el = $("#view-" + v);
  if (el) el.classList.add("active");
  if (v === "dash") { loadBadges(); loadLevel(); loadLeaderboard(); }
  if (v === "feed") loadFeed();
  if (v === "dm") { loadConversations(); markDmSeen(); }
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function initNav() {
  $$("[data-view]").forEach((b) => b.addEventListener("click", () => switchView(b.dataset.view)));
  // Avatar (en haut) → Profil
  const mp = $(".me-pill");
  if (mp) { mp.style.cursor = "pointer"; mp.addEventListener("click", () => switchView("profil")); }
  // Bouton central + → publier (va au Fil et ouvre la zone de publication)
  const create = $("#bn-create");
  if (create) create.addEventListener("click", () => {
    switchView("feed");
    setTimeout(() => { const i = $("#post-input"); if (i) { i.focus(); i.scrollIntoView({ block: "center", behavior: "smooth" }); } }, 100);
  });
}

/* Pastille de messages non lus (suivi local, sans SQL) */
function setUnreadBadge(n) {
  $$('[data-view="dm"]').forEach((btn) => {
    let b = btn.querySelector(".nav-badge");
    if (n > 0) {
      if (!b) { b = document.createElement("span"); b.className = "nav-badge"; btn.appendChild(b); }
      b.textContent = n > 9 ? "9+" : String(n);
    } else if (b) { b.remove(); }
  });
}
async function loadUnread() {
  const seen = localStorage.getItem("zx_dm_seen") || "1970-01-01T00:00:00Z";
  const { count } = await sb.from("dms").select("*", { count: "exact", head: true })
    .eq("recipient_id", state.user.id).gt("created_at", seen);
  setUnreadBadge(count || 0);
}
function markDmSeen() {
  localStorage.setItem("zx_dm_seen", new Date().toISOString());
  setUnreadBadge(0);
}

/* ============================================================
   SALONS DE CHAT (temps réel)
============================================================ */
async function initChat() {
  if (state.chatInit) return;
  state.chatInit = true;
  const { data: rooms } = await sb.from("rooms").select("*").order("sort", { ascending: true });
  state.rooms = rooms || [];
  const list = $("#rooms-list");
  list.innerHTML = "";
  state.rooms.forEach((room) => {
    const btn = document.createElement("button");
    btn.className = "room-btn";
    btn.dataset.id = room.id;
    btn.innerHTML = `<span class="em"></span><span class="nm"></span>`;
    btn.querySelector(".em").innerHTML = roomIcon(room.slug);
    btn.querySelector(".nm").textContent = room.name;
    btn.addEventListener("click", () => selectRoom(room));
    list.appendChild(btn);
  });
  if (state.rooms.length) selectRoom(state.rooms[0]);

  startPresence();

  // Réactions en temps réel
  state.reactChannel = sb.channel("reactions")
    .on("postgres_changes", { event: "*", schema: "public", table: "message_reactions" }, () => {
      if ($("#view-chat").classList.contains("active")) loadReactionsForVisible();
    })
    .subscribe();

  // Composer
  const input = $("#msg-input");
  input.addEventListener("input", () => {
    input.style.height = "46px";
    input.style.height = Math.min(input.scrollHeight, 140) + "px";
  });
  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      $("#composer").requestSubmit();
    }
  });
  $("#composer").addEventListener("submit", sendMessage);
}

async function selectRoom(room) {
  state.currentRoom = room;
  const token = room.id;
  state._roomToken = token;
  $$(".room-btn").forEach((b) => b.classList.toggle("active", b.dataset.id === room.id));
  const rt = $("#room-title");
  rt.innerHTML = roomIcon(room.slug);
  rt.appendChild(document.createTextNode(" " + room.name));
  $("#room-desc").textContent = room.description || "";

  const box = $("#messages");
  box.innerHTML = `<div class="chat-empty">Chargement…</div>`;

  const { data: msgs } = await sb
    .from("messages")
    .select("id, content, created_at, user_id, profiles(pseudo, avatar_emoji, avatar_url, level)")
    .eq("room_id", room.id)
    .order("created_at", { ascending: true })
    .limit(100);

  // Si l'utilisateur a changé de salon entre-temps, on abandonne ce rendu.
  if (state._roomToken !== token) return;
  box.innerHTML = "";
  if (!msgs || !msgs.length) {
    box.innerHTML = `<div class="chat-empty">Aucun message pour l'instant.<br>Sois la première voix douce de ce salon.</div>`;
  } else {
    msgs.forEach(renderMessage);
    scrollChat();
  }
  loadReactionsForVisible();

  // (Re)souscription temps réel
  if (state.roomChannel) sb.removeChannel(state.roomChannel);
  state.roomChannel = sb
    .channel("room:" + room.id)
    .on(
      "postgres_changes",
      { event: "INSERT", schema: "public", table: "messages", filter: "room_id=eq." + room.id },
      async (payload) => {
        const m = payload.new;
        // Récupère le profil de l'auteur
        let pseudo = "Membre", emoji = "🌙", url = null, lvl = 1;
        if (m.user_id === state.user.id) {
          pseudo = state.profile.pseudo; emoji = state.profile.avatar_emoji; url = state.profile.avatar_url; lvl = state.level;
        } else {
          const { data: p } = await sb.from("profiles").select("pseudo, avatar_emoji, avatar_url, level").eq("id", m.user_id).maybeSingle();
          if (p) { pseudo = p.pseudo; emoji = p.avatar_emoji; url = p.avatar_url; lvl = p.level; }
        }
        if ($(".chat-empty", box)) box.innerHTML = "";
        renderMessage({ ...m, profiles: { pseudo, avatar_emoji: emoji, avatar_url: url, level: lvl } });
        scrollChat();
      }
    )
    .subscribe();
}

function renderMessage(m) {
  const box = $("#messages");
  if (m.id && box.querySelector('[data-mid="' + m.id + '"]')) return; // anti-doublon
  const mine = m.user_id === state.user.id;
  const wrap = document.createElement("div");
  wrap.className = "msg" + (mine ? " mine" : "");
  wrap.dataset.uid = m.user_id;
  wrap.dataset.mid = m.id;
  const prev = box.lastElementChild;
  if (prev && prev.dataset && prev.dataset.uid === m.user_id) wrap.classList.add("grouped");
  const who = (m.profiles && m.profiles.pseudo) || "Membre";
  const meta = document.createElement("div");
  meta.className = "meta";
  const av = document.createElement("span");
  av.className = "av";
  applyAvatar(av, who, m.user_id, m.profiles && m.profiles.avatar_url, m.profiles && m.profiles.level);
  const whoSpan = document.createElement("span");
  whoSpan.className = "who";
  whoSpan.textContent = mine ? "Toi" : who;
  meta.appendChild(av);
  meta.appendChild(whoSpan);
  meta.appendChild(document.createTextNode(" · " + fmtTime(m.created_at)));
  const bubble = document.createElement("div");
  bubble.className = "bubble";
  bubble.textContent = m.content;
  wrap.appendChild(meta);
  wrap.appendChild(bubble);
  const reacts = document.createElement("div");
  reacts.className = "msg-reacts";
  wrap.appendChild(reacts);

  if (state.isAdmin || mine) {
    const mod = document.createElement("div");
    mod.className = "msg-mod";
    const del = document.createElement("button");
    del.type = "button"; del.className = "mod-btn"; del.textContent = "Supprimer";
    del.onclick = async () => {
      const { error } = await sb.from("messages").delete().eq("id", m.id);
      if (error) { toast("Suppression impossible."); return; }
      wrap.remove();
    };
    mod.appendChild(del);
    if (state.isAdmin && !mine) {
      const ban = document.createElement("button");
      ban.type = "button"; ban.className = "mod-btn ban"; ban.textContent = "Bannir";
      ban.onclick = () => banUser(m.user_id, who);
      mod.appendChild(ban);
    }
    wrap.appendChild(mod);
  }
  box.appendChild(wrap);
}

async function banUser(uid, pseudo) {
  if (uid === state.user.id) { toast("Tu ne peux pas te bannir toi-même."); return; }
  if (!confirm("Bannir " + (pseudo || "ce membre") + " ? Il ne pourra plus rien publier.")) return;
  const { error } = await sb.from("profiles").update({ is_banned: true }).eq("id", uid);
  toast(error ? "Action impossible." : "Membre banni.");
  if (!error && state.isAdmin) loadAdmin();
}

/* ---------- Réactions emoji sur les messages ---------- */
const REACT_EMOJIS = ["❤️", "🙏", "✨", "🫂", "😢", "👏"];

async function loadReactionsForVisible() {
  const els = $$("#messages .msg");
  const mids = els.map((el) => el.dataset.mid).filter(Boolean);
  if (!mids.length) return;
  const { data } = await sb.from("message_reactions").select("message_id, emoji, user_id").in("message_id", mids);
  const byMsg = {};
  (data || []).forEach((r) => {
    const mm = (byMsg[r.message_id] = byMsg[r.message_id] || {});
    const a = (mm[r.emoji] = mm[r.emoji] || { count: 0, mine: false });
    a.count++;
    if (r.user_id === state.user.id) a.mine = true;
  });
  els.forEach((el) => renderReactsBar(el, el.dataset.mid, byMsg[el.dataset.mid] || {}));
}

function renderReactsBar(el, mid, agg) {
  let bar = el.querySelector(".msg-reacts");
  if (!bar) { bar = document.createElement("div"); bar.className = "msg-reacts"; el.appendChild(bar); }
  bar.innerHTML = "";
  Object.keys(agg).forEach((em) => {
    const a = agg[em];
    if (!a || a.count <= 0) return;
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = "react-chip" + (a.mine ? " mine" : "");
    const es = document.createElement("span"); es.textContent = em;
    const cs = document.createElement("span"); cs.className = "rc"; cs.textContent = a.count;
    chip.appendChild(es); chip.appendChild(cs);
    chip.onclick = () => toggleReaction(mid, em);
    bar.appendChild(chip);
  });
  const add = document.createElement("button");
  add.type = "button"; add.className = "react-add"; add.textContent = "☺";
  const picker = document.createElement("div"); picker.className = "react-picker";
  REACT_EMOJIS.forEach((em) => {
    const b = document.createElement("button");
    b.type = "button"; b.textContent = em;
    b.onclick = () => { picker.classList.remove("open"); toggleReaction(mid, em); };
    picker.appendChild(b);
  });
  add.onclick = () => picker.classList.toggle("open");
  bar.appendChild(add);
  bar.appendChild(picker);
}

async function toggleReaction(mid, emoji) {
  const { data: existing } = await sb.from("message_reactions")
    .select("id").eq("message_id", mid).eq("user_id", state.user.id).eq("emoji", emoji).maybeSingle();
  if (existing) await sb.from("message_reactions").delete().eq("id", existing.id);
  else await sb.from("message_reactions").insert({ message_id: mid, user_id: state.user.id, emoji });
  loadReactionsForVisible();
}

/* Présence en ligne (temps réel) */
function startPresence() {
  if (state.presenceChannel) return;
  const ch = sb.channel("online", { config: { presence: { key: state.user.id } } });
  ch.on("presence", { event: "sync" }, () => {
    const n = Object.keys(ch.presenceState()).length;
    $("#online").innerHTML = '<span class="dot"></span>' + n + " " + (n > 1 ? "membres veillent" : "membre veille");
  }).subscribe(async (status) => {
    if (status === "SUBSCRIBED") await ch.track({ pseudo: state.profile.pseudo });
  });
  state.presenceChannel = ch;
}

function scrollChat() {
  const box = $("#messages");
  box.scrollTop = box.scrollHeight;
}

async function sendMessage(e) {
  e.preventDefault();
  if (state._sending) return;
  const input = $("#msg-input");
  const content = input.value.trim();
  if (!content || !state.currentRoom) return;
  state._sending = true;
  input.value = "";
  input.style.height = "46px";
  const { error } = await sb.from("messages").insert({
    room_id: state.currentRoom.id,
    user_id: state.user.id,
    content,
  });
  state._sending = false;
  if (error) {
    toast("Message non envoyé. Réessaie.");
    input.value = content;
  }
}

/* ============================================================
   MON ESPACE (défi, fiche de route, évolution)
============================================================ */
async function initDashboard() {
  const hour = new Date().getHours();
  const greet = hour >= 22 || hour < 6 ? "Bonne nuit" : hour < 18 ? "Bonjour" : "Bonsoir";
  $("#dash-hello").textContent = `${greet}, ${state.profile.pseudo}.`;
  applyAvatar($("#dash-av"), state.profile.pseudo, state.user.id, state.profile.avatar_url);
  setQuote();
  initBreathing();
  initGrounding();

  await loadChallenge();
  await loadRoadmap();
  await loadMood();
  await loadBadges();
  await loadLevel();
  loadLeaderboard();
  subscribeMood();

  // Fiche de route : ajout
  $("#rm-add").addEventListener("submit", async (e) => {
    e.preventDefault();
    const inp = $("#rm-input");
    const title = inp.value.trim();
    if (!title) return;
    inp.value = "";
    const { error } = await sb.from("roadmap_items").insert({ user_id: state.user.id, title });
    if (error) return toast("Oups, impossible d'ajouter.");
    await loadRoadmap();
  });

  // Humeur : sélection
  $$("#mood-pick button").forEach((b) => {
    b.addEventListener("click", () => {
      $$("#mood-pick button").forEach((x) => x.classList.remove("sel"));
      b.classList.add("sel");
      state.selectedMood = parseInt(b.dataset.score, 10);
      $("#mood-save").disabled = false;
    });
  });
  $("#mood-save").addEventListener("click", async () => {
    if (!state.selectedMood) return;
    const note = $("#mood-note").value.trim() || null;
    const { error } = await sb.from("mood_logs").insert({ user_id: state.user.id, score: state.selectedMood, note });
    if (error) return toast("Impossible d'enregistrer.");
    state.selectedMood = null;
    $("#mood-note").value = "";
    $$("#mood-pick button").forEach((x) => x.classList.remove("sel"));
    $("#mood-save").disabled = true;
    toast("Humeur enregistrée ✦");
    await loadMood();
    await loadBadges();
  });
}

/* ============================================================
   Réussites / badges (calculés à partir des données)
============================================================ */
async function loadBadges() {
  const uid = state.user.id;
  const [msg, mood, ch, rm] = await Promise.all([
    sb.from("messages").select("*", { count: "exact", head: true }).eq("user_id", uid),
    sb.from("mood_logs").select("*", { count: "exact", head: true }).eq("user_id", uid),
    sb.from("challenge_completions").select("*", { count: "exact", head: true }).eq("user_id", uid),
    sb.from("roadmap_items").select("done").eq("user_id", uid),
  ]);
  const msgC = msg.count || 0, moodC = mood.count || 0, chC = ch.count || 0;
  const rmDone = (rm.data || []).filter((i) => i.done).length;
  const defs = [
    { ic: "message", n: "Première parole", d: "1er message", ok: msgC >= 1 },
    { ic: "chart", n: "Voix de la nuit", d: "10 messages", ok: msgC >= 10 },
    { ic: "heart", n: "À l'écoute", d: "3 humeurs notées", ok: moodC >= 3 },
    { ic: "moon", n: "Sept nuits", d: "7 humeurs notées", ok: moodC >= 7 },
    { ic: "flame", n: "Premier défi", d: "1 défi relevé", ok: chC >= 1 },
    { ic: "award", n: "Persévérance", d: "5 défis relevés", ok: chC >= 5 },
    { ic: "compass", n: "En route", d: "1 objectif atteint", ok: rmDone >= 1 },
    { ic: "star", n: "Présent·e", d: "Tu es là, ce soir", ok: true },
  ];
  const box = $("#badges");
  box.innerHTML = "";
  defs.forEach((b) => {
    const el = document.createElement("div");
    el.className = "badge " + (b.ok ? "earned" : "locked");
    el.innerHTML = `<span class="be"></span><span class="bn"></span><span class="bd"></span>`;
    el.querySelector(".be").innerHTML = icon(b.ic);
    el.querySelector(".bn").textContent = b.n;
    el.querySelector(".bd").textContent = b.d;
    box.appendChild(el);
  });
}

/* ============================================================
   Respiration guidée (inspire 4s · retiens 4s · expire 6s)
============================================================ */
function initBreathing() {
  if (state.breatheInit) return;
  state.breatheInit = true;
  let running = false;
  let timers = [];
  const btn = $("#breathe-btn"), orb = $("#breathe-orb"), txt = $("#breathe-text");

  function stop() {
    running = false;
    timers.forEach(clearTimeout);
    timers = [];
    orb.style.transitionDuration = "1s";
    orb.style.transform = "scale(0.55)";
    txt.textContent = "Prêt ?";
    btn.textContent = "Commencer";
  }
  function phase(text, dur, scale) {
    return new Promise((res) => {
      txt.textContent = text;
      orb.style.transitionDuration = dur + "ms";
      orb.style.transform = "scale(" + scale + ")";
      timers.push(setTimeout(res, dur));
    });
  }
  async function cycle() {
    while (running) {
      await phase("Inspire…", 4000, 1);
      if (!running) break;
      await phase("Retiens…", 4000, 1);
      if (!running) break;
      await phase("Expire…", 6000, 0.55);
    }
  }
  btn.addEventListener("click", () => {
    if (running) { stop(); return; }
    running = true;
    btn.textContent = "Arrêter";
    cycle();
  });
}

/* ============================================================
   Ancrage 5-4-3-2-1
============================================================ */
function initGrounding() {
  if (state.groundInit) return;
  state.groundInit = true;
  const STEPS = [
    { n: "5", t: "Nomme 5 choses que tu peux VOIR autour de toi." },
    { n: "4", t: "Nomme 4 choses que tu peux TOUCHER." },
    { n: "3", t: "Nomme 3 choses que tu peux ENTENDRE." },
    { n: "2", t: "Nomme 2 choses que tu peux SENTIR (des odeurs)." },
    { n: "1", t: "Nomme 1 chose que tu peux GOÛTER." },
  ];
  const btn = $("#ground-btn"), num = $("#ground-num"), txt = $("#ground-txt");
  let i = -1;
  function show() {
    if (i >= STEPS.length) {
      num.classList.remove("active");
      num.textContent = "🤍";
      txt.textContent = "Tu es là, dans le présent. Respire. C'était courageux.";
      btn.textContent = "Recommencer";
      i = -1;
      return;
    }
    const s = STEPS[i];
    num.classList.add("active");
    num.textContent = s.n;
    txt.textContent = s.t;
    btn.textContent = i === STEPS.length - 1 ? "Terminer" : "Suivant";
  }
  btn.addEventListener("click", () => { i++; show(); });
}

async function loadChallenge() {
  const { data: ch } = await sb.from("challenges").select("*").eq("is_active", true).order("created_at", { ascending: false }).maybeSingle();
  state.challenge = ch;
  if (!ch) {
    $("#ch-title").textContent = "Bientôt un nouveau défi…";
    $("#ch-desc").textContent = "";
    $("#ch-btn").style.display = "none";
    return;
  }
  $("#ch-title").textContent = ch.title;
  $("#ch-desc").textContent = ch.description || "";

  // Total de défis relevés
  const { count } = await sb
    .from("challenge_completions")
    .select("*", { count: "exact", head: true })
    .eq("user_id", state.user.id);
  $("#ch-count").textContent = count || 0;
  $("#stat-def").textContent = count || 0;

  // Ce défi est-il déjà relevé ?
  const { data: done } = await sb
    .from("challenge_completions")
    .select("id")
    .eq("user_id", state.user.id)
    .eq("challenge_id", ch.id)
    .maybeSingle();
  setChallengeDone(!!done);

  $("#ch-btn").onclick = async () => {
    const isDone = $("#ch-btn").dataset.done === "1";
    if (isDone) {
      await sb.from("challenge_completions").delete().eq("user_id", state.user.id).eq("challenge_id", ch.id);
    } else {
      await sb.from("challenge_completions").insert({ user_id: state.user.id, challenge_id: ch.id });
      toast("Bravo ✦ Un pas de plus.");
    }
    await loadChallenge();
  };
}

function setChallengeDone(done) {
  const btn = $("#ch-btn");
  btn.dataset.done = done ? "1" : "0";
  btn.textContent = done ? "✓ Défi relevé cette semaine" : "Marquer comme fait";
  btn.classList.toggle("btn-ghost", done);
  btn.classList.toggle("btn-gold", !done);
}

async function loadRoadmap() {
  const { data: items } = await sb
    .from("roadmap_items")
    .select("*")
    .eq("user_id", state.user.id)
    .order("done", { ascending: true })
    .order("created_at", { ascending: true });
  const list = $("#rm-list");
  list.innerHTML = "";
  const arr = items || [];
  if (!arr.length) {
    list.innerHTML = `<div class="chart-empty">Ajoute un premier objectif, même tout petit.</div>`;
  }
  arr.forEach((it) => {
    const row = document.createElement("div");
    row.className = "rm-item" + (it.done ? " done" : "");
    const check = document.createElement("button");
    check.className = "rm-check" + (it.done ? " done" : "");
    check.innerHTML = it.done ? "✓" : "";
    check.onclick = async () => {
      await sb.from("roadmap_items").update({ done: !it.done }).eq("id", it.id);
      await loadRoadmap();
    };
    const txt = document.createElement("div");
    txt.className = "rm-txt";
    txt.textContent = it.title;
    const del = document.createElement("button");
    del.className = "rm-del";
    del.textContent = "×";
    del.title = "Supprimer";
    del.onclick = async () => {
      await sb.from("roadmap_items").delete().eq("id", it.id);
      await loadRoadmap();
    };
    row.appendChild(check);
    row.appendChild(txt);
    row.appendChild(del);
    list.appendChild(row);
  });
  const total = arr.length;
  const done = arr.filter((i) => i.done).length;
  $("#rm-bar").style.width = (total ? (done / total) * 100 : 0) + "%";
  const so = $("#stat-obj"); if (so) so.textContent = done;
}

async function loadMood() {
  const { data: logs } = await sb
    .from("mood_logs")
    .select("score, created_at")
    .eq("user_id", state.user.id)
    .order("created_at", { ascending: false })
    .limit(14);
  const arr = (logs || []).reverse();
  const chart = $("#mood-chart");
  chart.innerHTML = "";
  if (!arr.length) {
    $("#mood-avg").innerHTML = "";
    const sm = $("#stat-mood"); if (sm) sm.textContent = "–";
    chart.innerHTML = `<div class="chart-empty">Enregistre ton humeur pour voir ta courbe apparaître.</div>`;
    return;
  }
  arr.forEach((l) => {
    const bar = document.createElement("div");
    bar.className = "bar";
    bar.style.height = (l.score / 5) * 100 + "%";
    bar.title = new Date(l.created_at).toLocaleDateString("fr-FR", { day: "numeric", month: "short" }) + " — " + l.score + "/5";
    chart.appendChild(bar);
  });
  const avg = (arr.reduce((s, l) => s + l.score, 0) / arr.length).toFixed(1);
  $("#mood-avg").innerHTML = `Moyenne récente : <b>${avg} / 5</b> · ${arr.length} relevé${arr.length > 1 ? "s" : ""}`;
  const sm = $("#stat-mood"); if (sm) sm.textContent = avg;
}

function subscribeMood() {
  if (state.moodChannel) return;
  state.moodChannel = sb
    .channel("mood:" + state.user.id)
    .on(
      "postgres_changes",
      { event: "INSERT", schema: "public", table: "mood_logs", filter: "user_id=eq." + state.user.id },
      () => loadMood()
    )
    .subscribe();
}

/* ============================================================
   PROFIL
============================================================ */
function initProfile() {
  $("#pf-pseudo").textContent = state.profile.pseudo;
  $("#pf-email").textContent = state.user.email || "—";
  applyAvatar($("#pf-av"), state.profile.pseudo, state.user.id, state.profile.avatar_url);

  // Changer la photo de profil
  const photoBtn = $("#pf-photo-btn"), photoInput = $("#pf-photo-input"), photoHint = $("#pf-photo-hint");
  photoBtn.addEventListener("click", () => photoInput.click());
  photoInput.addEventListener("change", async () => {
    const file = photoInput.files && photoInput.files[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) { toast("Image trop lourde (5 Mo max)."); return; }
    photoHint.textContent = "Envoi en cours…";
    const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
    const path = `${state.user.id}/avatar_${Date.now()}.${ext}`;
    const { error: upErr } = await sb.storage.from("avatars").upload(path, file, { upsert: true, cacheControl: "3600", contentType: file.type || undefined });
    if (upErr) { photoHint.textContent = "Échec : " + (upErr.message || "erreur inconnue"); toast("Échec : " + (upErr.message || "erreur")); return; }
    const { data: pub } = sb.storage.from("avatars").getPublicUrl(path);
    const url = pub.publicUrl;
    const { error: dbErr } = await sb.from("profiles").update({ avatar_url: url }).eq("id", state.user.id);
    if (dbErr) { photoHint.textContent = "Erreur d'enregistrement."; return; }
    state.profile.avatar_url = url;
    refreshMyAvatars();
    photoHint.textContent = "JPG, PNG, GIF ou WebP · 2 Mo max";
    toast("Photo de profil mise à jour ✦");
  });
  $("#pf-anon").checked = !!state.profile.is_anonymous;
  const since = state.profile.created_at ? new Date(state.profile.created_at) : new Date();
  $("#pf-since").textContent = since.toLocaleDateString("fr-FR", { day: "numeric", month: "long", year: "numeric" });

  $("#pf-anon").addEventListener("change", async (e) => {
    const val = e.target.checked;
    const { error } = await sb.from("profiles").update({ is_anonymous: val }).eq("id", state.user.id);
    if (error) { toast("Modification impossible."); e.target.checked = !val; return; }
    state.profile.is_anonymous = val;
    toast(val ? "Tu es maintenant anonyme." : "Profil visible.");
  });

  $("#btn-logout").addEventListener("click", async () => {
    try { if (navigator.serviceWorker && navigator.serviceWorker.controller) navigator.serviceWorker.controller.postMessage("zx-clear-cache"); } catch (e) {}
    await sb.auth.signOut();
    location.href = "index.html";
  });
}

/* ============================================================
   FIL DE PUBLICATIONS
============================================================ */
let feedImageFile = null;

function timeAgo(iso) {
  const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return "à l'instant";
  const m = Math.floor(s / 60); if (m < 60) return "il y a " + m + " min";
  const h = Math.floor(m / 60); if (h < 24) return "il y a " + h + " h";
  const d = Math.floor(h / 24); if (d < 7) return "il y a " + d + " j";
  return new Date(iso).toLocaleDateString("fr-FR", { day: "numeric", month: "short" });
}

function initFeed() {
  if (state.feedInit) return;
  state.feedInit = true;
  const input = $("#post-input"), photoBtn = $("#post-photo-btn"), photoInput = $("#post-photo-input"),
        preview = $("#post-preview"), previewImg = $("#post-preview-img"), previewDel = $("#post-preview-del"),
        sendBtn = $("#post-send");

  photoBtn.addEventListener("click", () => photoInput.click());
  photoInput.addEventListener("change", () => {
    const f = photoInput.files && photoInput.files[0];
    if (!f) return;
    if (f.size > 5 * 1024 * 1024) { toast("Image trop lourde (5 Mo max)."); photoInput.value = ""; return; }
    feedImageFile = f;
    previewImg.src = URL.createObjectURL(f);
    preview.hidden = false;
  });
  previewDel.addEventListener("click", () => {
    feedImageFile = null; photoInput.value = ""; preview.hidden = true; previewImg.src = "";
  });

  sendBtn.addEventListener("click", async () => {
    const content = input.value.trim();
    if (!content && !feedImageFile) { toast("Écris quelque chose…"); return; }
    sendBtn.disabled = true;
    let imageUrl = null;
    if (feedImageFile) {
      const ext = (feedImageFile.name.split(".").pop() || "jpg").toLowerCase();
      const path = `${state.user.id}/post_${Date.now()}.${ext}`;
      const { error: upErr } = await sb.storage.from("avatars").upload(path, feedImageFile, { upsert: true, contentType: feedImageFile.type || undefined });
      if (!upErr) imageUrl = sb.storage.from("avatars").getPublicUrl(path).data.publicUrl;
    }
    const { error } = await sb.from("posts").insert({ user_id: state.user.id, content: content || " ", image_url: imageUrl });
    sendBtn.disabled = false;
    if (error) { toast("Publication impossible."); return; }
    input.value = ""; feedImageFile = null; photoInput.value = ""; preview.hidden = true; previewImg.src = "";
    toast("Publié ✦");
    await loadFeed();
  });

  state.feedChannel = sb.channel("feed")
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "posts" }, () => {
      if ($("#view-feed").classList.contains("active")) loadFeed();
    })
    .subscribe();

  loadFeed();
}

async function loadFeed() {
  const list = $("#feed-list");
  const { data: posts } = await sb.from("posts")
    .select("id,content,image_url,created_at,user_id,profiles(pseudo,avatar_url,level),post_likes(count),post_comments(count)")
    .order("created_at", { ascending: false })
    .limit(50);
  const { data: myLikes } = await sb.from("post_likes").select("post_id").eq("user_id", state.user.id);
  const liked = new Set((myLikes || []).map((l) => l.post_id));
  list.innerHTML = "";
  if (!posts || !posts.length) {
    list.innerHTML = `<div class="feed-empty">Aucune publication pour l'instant.<br>Sois le premier à partager quelque chose.</div>`;
    return;
  }
  posts.forEach((p) => list.appendChild(renderPost(p, liked.has(p.id))));
}

function renderPost(p, isLiked) {
  const who = (p.profiles && p.profiles.pseudo) || "Membre";
  const url = p.profiles && p.profiles.avatar_url;
  const likeCount = (p.post_likes && p.post_likes[0] && p.post_likes[0].count) || 0;
  const cmtCount = (p.post_comments && p.post_comments[0] && p.post_comments[0].count) || 0;
  const art = document.createElement("article");
  art.className = "post"; art.dataset.id = p.id;

  const head = document.createElement("div"); head.className = "post-head";
  const av = document.createElement("span"); av.className = "post-av"; applyAvatar(av, who, p.user_id, url, p.profiles && p.profiles.level);
  const info = document.createElement("div");
  const w = document.createElement("div"); w.className = "who"; w.textContent = p.user_id === state.user.id ? "Toi" : who;
  const tm = document.createElement("div"); tm.className = "time"; tm.textContent = timeAgo(p.created_at);
  info.appendChild(w); info.appendChild(tm);
  head.appendChild(av); head.appendChild(info);
  if (p.user_id === state.user.id || state.isAdmin) {
    const del = document.createElement("button"); del.className = "post-del"; del.textContent = "×"; del.title = "Supprimer";
    del.onclick = async () => { if (!confirm("Supprimer cette publication ?")) return; await sb.from("posts").delete().eq("id", p.id); await loadFeed(); };
    head.appendChild(del);
  }
  art.appendChild(head);

  if (p.content && p.content.trim()) {
    const body = document.createElement("div"); body.className = "post-body"; body.textContent = p.content; art.appendChild(body);
  }
  if (p.image_url) {
    const img = document.createElement("img"); img.className = "post-img"; img.loading = "lazy"; img.src = p.image_url; img.alt = "";
    img.onerror = () => img.remove();
    art.appendChild(img);
  }

  const actions = document.createElement("div"); actions.className = "post-actions";
  const likeBtn = document.createElement("button"); likeBtn.className = "post-like" + (isLiked ? " liked" : "");
  likeBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 1 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/></svg><span class="lc">${likeCount}</span>`;
  let liked = isLiked, lc = likeCount;
  likeBtn.onclick = async () => {
    liked = !liked;
    likeBtn.classList.toggle("liked", liked);
    lc += liked ? 1 : -1; likeBtn.querySelector(".lc").textContent = lc;
    if (liked) await sb.from("post_likes").insert({ post_id: p.id, user_id: state.user.id });
    else await sb.from("post_likes").delete().eq("post_id", p.id).eq("user_id", state.user.id);
  };
  const cmtBtn = document.createElement("button"); cmtBtn.className = "post-cmt";
  cmtBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M21 11.5a8.4 8.4 0 0 1-12.4 7.4L3 21l2.1-5.6A8.4 8.4 0 1 1 21 11.5Z"/></svg><span class="cc">${cmtCount}</span>`;
  actions.appendChild(likeBtn); actions.appendChild(cmtBtn);
  art.appendChild(actions);

  const cbox = document.createElement("div"); cbox.className = "post-comments";
  const clist = document.createElement("div"); clist.className = "cmt-list";
  const cform = document.createElement("form"); cform.className = "cmt-add";
  const cin = document.createElement("input"); cin.className = "field"; cin.placeholder = "Écrire un commentaire…"; cin.maxLength = 1000;
  const cbtn = document.createElement("button"); cbtn.type = "submit"; cbtn.textContent = "→";
  cform.appendChild(cin); cform.appendChild(cbtn);
  cbox.appendChild(clist); cbox.appendChild(cform);
  art.appendChild(cbox);

  let loaded = false;
  cmtBtn.onclick = async () => {
    cbox.classList.toggle("open");
    if (cbox.classList.contains("open") && !loaded) { loaded = true; await loadComments(p.id, clist); }
  };
  cform.addEventListener("submit", async (e) => {
    e.preventDefault();
    const txt = cin.value.trim(); if (!txt) return; cin.value = "";
    const { error } = await sb.from("post_comments").insert({ post_id: p.id, user_id: state.user.id, content: txt });
    if (error) { toast("Commentaire impossible."); return; }
    await loadComments(p.id, clist);
    const cc = cmtBtn.querySelector(".cc"); cc.textContent = (parseInt(cc.textContent, 10) || 0) + 1;
  });

  return art;
}

async function loadComments(postId, listEl) {
  const { data: cs } = await sb.from("post_comments")
    .select("id,content,created_at,user_id,profiles(pseudo,avatar_url,level)")
    .eq("post_id", postId)
    .order("created_at", { ascending: true });
  listEl.innerHTML = "";
  (cs || []).forEach((c) => {
    const who = (c.profiles && c.profiles.pseudo) || "Membre";
    const row = document.createElement("div"); row.className = "cmt";
    const av = document.createElement("span"); av.className = "cmt-av"; applyAvatar(av, who, c.user_id, c.profiles && c.profiles.avatar_url, c.profiles && c.profiles.level);
    const bub = document.createElement("div"); bub.className = "cmt-bub";
    const wn = document.createElement("span"); wn.className = "cmt-who"; wn.textContent = c.user_id === state.user.id ? "Toi" : who;
    bub.appendChild(wn); bub.appendChild(document.createTextNode(c.content));
    row.appendChild(av); row.appendChild(bub);
    listEl.appendChild(row);
  });
}

/* ============================================================
   SYSTÈME DE NIVEAUX (XP selon l'activité)
============================================================ */
function titleForLevel(lvl) {
  lvl = lvl || 1;
  if (lvl >= 100) return "Légende";
  if (lvl >= 90) return "Étoile";
  if (lvl >= 70) return "Phare";
  if (lvl >= 50) return "Lumière";
  if (lvl >= 40) return "Gardien·ne";
  if (lvl >= 30) return "Pilier";
  if (lvl >= 20) return "Confident·e";
  if (lvl >= 10) return "Veilleur·se";
  if (lvl >= 5) return "Présence";
  return "Nouvelle âme";
}

function levelFromXp(xp) {
  let lvl = 1;
  while (50 * (lvl + 1) * lvl <= xp) lvl++;
  const cum = (L) => 50 * L * (L - 1);
  const into = xp - cum(lvl);
  const need = 100 * lvl;
  return { lvl, into, need, pct: Math.min(100, Math.round((into / need) * 100)), remaining: Math.max(0, need - into) };
}

async function loadLevel() {
  const uid = state.user.id;
  const q = (t) => sb.from(t).select("*", { count: "exact", head: true }).eq("user_id", uid);
  const [msg, posts, cmts, mood, ch, likes, reacts, rm] = await Promise.all([
    q("messages"), q("posts"), q("post_comments"), q("mood_logs"), q("challenge_completions"), q("post_likes"), q("message_reactions"),
    sb.from("roadmap_items").select("done").eq("user_id", uid),
  ]);
  const rmDone = ((rm.data) || []).filter((i) => i.done).length;
  const xp = (msg.count || 0) * 5 + (posts.count || 0) * 15 + (cmts.count || 0) * 8 + (mood.count || 0) * 10
           + (ch.count || 0) * 25 + rmDone * 20 + (likes.count || 0) * 2 + (reacts.count || 0) * 2
           + (state.profile.bonus_xp || 0);
  const L = levelFromXp(xp);
  const title = titleForLevel(L.lvl);
  const setT = (id, v) => { const e = $("#" + id); if (e) e.textContent = v; };
  setT("lvl-num", L.lvl);
  setT("lvl-title", title + " · niveau " + L.lvl);
  setT("lvl-xp", xp + " XP");
  const bar = $("#lvl-bar"); if (bar) bar.style.width = L.pct + "%";
  setT("lvl-next", "Plus que " + L.remaining + " XP pour le niveau " + (L.lvl + 1));
  const chip = $("#lvl-chip"); if (chip) chip.textContent = "Nv " + L.lvl;
  state.level = L.lvl;
  // Mémorise le niveau dans le profil pour que les autres voient ton cadre partout
  if (state.profile.level !== L.lvl) {
    state.profile.level = L.lvl;
    sb.from("profiles").update({ level: L.lvl }).eq("id", state.user.id);
  }
  applyHalo();
  loadRewards();
}

/* ============================================================
   CLASSEMENT + RÉCOMPENSES
============================================================ */
async function loadLeaderboard() {
  const box = $("#leaderboard");
  if (!box) return;
  const { data, error } = await sb.rpc("leaderboard", { lim: 10 });
  if (error) { box.innerHTML = `<div class="chart-empty">Classement bientôt disponible.</div>`; return; }
  box.innerHTML = "";
  (data || []).forEach((row, i) => {
    const lvl = levelFromXp(row.xp || 0).lvl;
    const el = document.createElement("div");
    el.className = "lb-row" + (row.id === state.user.id ? " me" : "") + (i < 3 ? " top" : "");
    const rank = document.createElement("div"); rank.className = "lb-rank"; rank.textContent = (i + 1);
    const av = document.createElement("span"); av.className = "lb-av"; applyAvatar(av, row.pseudo, row.id, row.avatar_url, lvl);
    const info = document.createElement("div"); info.style.flex = "1"; info.style.minWidth = "0";
    const nm = document.createElement("div"); nm.className = "lb-name"; nm.textContent = row.id === state.user.id ? (row.pseudo + " (toi)") : row.pseudo;
    const lv = document.createElement("div"); lv.className = "lb-lvl"; lv.textContent = "Niveau " + lvl;
    info.appendChild(nm); info.appendChild(lv);
    const xp = document.createElement("div"); xp.className = "lb-xp"; xp.textContent = (row.xp || 0) + " XP";
    el.appendChild(rank); el.appendChild(av); el.appendChild(info); el.appendChild(xp);
    box.appendChild(el);
  });
  if (!data || !data.length) box.innerHTML = `<div class="chart-empty">Personne au classement pour l'instant. Sois le premier ✦</div>`;
}

const REWARDS = [
  { lvl: 2, name: "Pastille de niveau", desc: "Ton niveau affiché en permanence" },
  { lvl: 5, name: "Cadre « Halo doux »", desc: "Ton premier cadre d'avatar" },
  { lvl: 10, name: "Titre « Veilleur·se »", desc: "Un titre qui évolue avec toi" },
  { lvl: 20, name: "Cadre « Lueur dorée »", desc: "Un cadre lumineux distinctif" },
  { lvl: 50, name: "Cadre « Dégradé royal »", desc: "Réservé aux membres dévoués" },
  { lvl: 70, name: "Cadres animés", desc: "Des cadres qui tournent autour de ton avatar" },
  { lvl: 100, name: "Statut Légende", desc: "Le rang ultime de Zymlux ✦" },
];

function loadRewards() {
  const box = $("#rewards");
  if (!box) return;
  const lvl = state.level || 1;
  box.innerHTML = "";
  REWARDS.forEach((r) => {
    const unlocked = lvl >= r.lvl;
    const el = document.createElement("div");
    el.className = "reward " + (unlocked ? "unlocked" : "locked");
    const badge = document.createElement("div"); badge.className = "rw-lvl"; badge.textContent = "Nv " + r.lvl;
    const info = document.createElement("div"); info.className = "rw-info";
    const nm = document.createElement("div"); nm.className = "rw-name"; nm.textContent = r.name;
    const ds = document.createElement("div"); ds.className = "rw-desc"; ds.textContent = r.desc;
    info.appendChild(nm); info.appendChild(ds);
    const st = document.createElement("div"); st.className = "rw-state"; st.textContent = unlocked ? "Débloqué ✦" : "Niveau " + r.lvl;
    el.appendChild(badge); el.appendChild(info); el.appendChild(st);
    box.appendChild(el);
  });
}

/* ---------- Cadres d'avatar (évoluent jusqu'au niveau 100) ---------- */
const FRAME_TIERS = [
  { lvl: 1,   cls: "fr-1",  name: "Sans cadre" },
  { lvl: 5,   cls: "fr-2",  name: "Halo doux" },
  { lvl: 10,  cls: "fr-3",  name: "Double anneau" },
  { lvl: 20,  cls: "fr-4",  name: "Lueur dorée" },
  { lvl: 30,  cls: "fr-5",  name: "Givre" },
  { lvl: 40,  cls: "fr-6",  name: "Aurore" },
  { lvl: 50,  cls: "fr-7",  name: "Dégradé royal" },
  { lvl: 60,  cls: "fr-8",  name: "Pulsation" },
  { lvl: 70,  cls: "fr-9",  name: "Couronne tournante" },
  { lvl: 80,  cls: "fr-10", name: "Orbite" },
  { lvl: 90,  cls: "fr-11", name: "Céleste" },
  { lvl: 100, cls: "fr-12", name: "Légende" },
];
const ALL_FRAME_CLS = FRAME_TIERS.map((t) => t.cls);
function frameClassForLevel(level) {
  let cls = "fr-1";
  const lvl = level || 1;
  FRAME_TIERS.forEach((t) => { if (lvl >= t.lvl) cls = t.cls; });
  return cls;
}
function currentFrame() { return frameClassForLevel(state.level); }
function applyHalo() {
  const cls = currentFrame();
  ["#me-av", "#dash-av", "#pf-av"].forEach((s) => {
    const e = $(s);
    if (!e) return;
    ALL_FRAME_CLS.forEach((c) => e.classList.remove(c));
    e.classList.add(cls);
  });
  loadFrames();
}

function loadFrames() {
  const box = $("#frames");
  if (!box) return;
  const lvl = state.level || 1;
  const cur = currentFrame();
  box.innerHTML = "";
  FRAME_TIERS.forEach((t) => {
    const unlocked = lvl >= t.lvl;
    const it = document.createElement("div");
    it.className = "frame-item" + (unlocked ? "" : " locked") + (t.cls === cur ? " active" : "");
    const pv = document.createElement("div"); pv.className = "frame-prev avatar " + t.cls; pv.textContent = "★";
    const nm = document.createElement("div"); nm.className = "frame-name"; nm.textContent = t.name;
    const lv = document.createElement("div"); lv.className = "frame-lvl"; lv.textContent = (t.cls === cur) ? "Actif" : ("Niveau " + t.lvl);
    it.appendChild(pv); it.appendChild(nm); it.appendChild(lv);
    box.appendChild(it);
  });
}

/* ============================================================
   ADMINISTRATION (chef absolu)
============================================================ */
function showBanned() {
  document.body.innerHTML =
    '<div style="min-height:100svh;display:flex;align-items:center;justify-content:center;padding:32px;text-align:center;font-family:var(--serif);">' +
    '<div style="max-width:420px;"><div style="font-size:1.8rem;color:#E5917A;margin-bottom:12px;">Compte suspendu</div>' +
    '<div style="font-family:var(--sans);font-weight:300;color:rgba(244,239,231,0.6);font-size:0.95rem;line-height:1.6;">Ton accès à la communauté a été suspendu par la modération.<br>Si tu penses qu\'il s\'agit d\'une erreur, contacte-nous.</div></div></div>';
}

async function loadAdmin() {
  const box = $("#admin-list");
  if (!box) return;
  const { data, error } = await sb.from("profiles")
    .select("id, pseudo, avatar_url, is_banned, is_admin, bonus_xp")
    .order("created_at", { ascending: false })
    .limit(100);
  if (error) { box.innerHTML = `<div class="chart-empty">Liste indisponible.</div>`; return; }
  box.innerHTML = "";
  (data || []).forEach((m) => {
    const row = document.createElement("div");
    row.className = "admin-row" + (m.is_banned ? " banned" : "");
    const av = document.createElement("span"); av.className = "lb-av"; applyAvatar(av, m.pseudo, m.id, m.avatar_url);
    const info = document.createElement("div"); info.style.flex = "1"; info.style.minWidth = "0";
    const nm = document.createElement("div"); nm.className = "lb-name";
    nm.textContent = m.pseudo + (m.is_admin ? " · admin" : "") + (m.id === state.user.id ? " (toi)" : "");
    const tag = document.createElement("div"); tag.className = "lb-lvl"; tag.textContent = m.is_banned ? "Banni" : "Actif";
    info.appendChild(nm); info.appendChild(tag);
    const actions = document.createElement("div"); actions.className = "admin-actions";

    // Cadeau d'XP (monte le membre en niveau)
    const gift = document.createElement("button");
    gift.className = "btn btn-ghost btn-sm"; gift.textContent = "Offrir XP";
    gift.onclick = async () => {
      const v = prompt("Combien d'XP offrir à " + m.pseudo + " ? (ex. 500)\nMets un nombre négatif pour en retirer.");
      if (v === null) return;
      const amount = parseInt(v, 10);
      if (isNaN(amount)) { toast("Nombre invalide."); return; }
      const newBonus = Math.max(0, (m.bonus_xp || 0) + amount);
      const { error: e } = await sb.from("profiles").update({ bonus_xp: newBonus }).eq("id", m.id);
      toast(e ? "Action impossible." : "Cadeau envoyé ✦");
      if (!e) { if (m.id === state.user.id) { state.profile.bonus_xp = newBonus; loadLevel(); } loadAdmin(); }
    };
    actions.appendChild(gift);

    // Bannir / débannir
    const btn = document.createElement("button");
    btn.className = "btn btn-ghost btn-sm";
    if (m.id === state.user.id || m.is_admin) {
      btn.textContent = "—"; btn.disabled = true; btn.style.opacity = "0.4";
    } else if (m.is_banned) {
      btn.textContent = "Débannir";
      btn.onclick = async () => { await sb.from("profiles").update({ is_banned: false }).eq("id", m.id); toast("Membre réintégré."); loadAdmin(); };
    } else {
      btn.textContent = "Bannir"; btn.classList.add("danger");
      btn.onclick = async () => { if (!confirm("Bannir " + m.pseudo + " ?")) return; await sb.from("profiles").update({ is_banned: true }).eq("id", m.id); toast("Membre banni."); loadAdmin(); };
    }
    actions.appendChild(btn);
    row.appendChild(av); row.appendChild(info); row.appendChild(actions);
    box.appendChild(row);
  });
}

/* ============================================================
   MESSAGES PRIVÉS (DM)
============================================================ */
function initDM() {
  if (state.dmInit) return;
  state.dmInit = true;
  state.dmWith = null;
  $("#dm-new").addEventListener("click", openMemberPicker);
  const input = $("#dm-input");
  input.addEventListener("input", () => { input.style.height = "48px"; input.style.height = Math.min(input.scrollHeight, 140) + "px"; });
  input.addEventListener("keydown", (e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); $("#dm-composer").requestSubmit(); } });
  $("#dm-composer").addEventListener("submit", sendDM);

  state.dmInChannel = sb.channel("dm-in")
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "dms", filter: "recipient_id=eq." + state.user.id }, (payload) => {
      const m = payload.new;
      if (state.dmWith === m.sender_id && $("#view-dm").classList.contains("active")) { appendDM(m); markDmSeen(); }
      else { toast("Nouveau message privé ✦"); loadUnread(); }
      loadConversations();
    })
    .subscribe();

  loadConversations();
  loadUnread();
}

async function loadConversations() {
  const box = $("#dm-convos");
  if (!box) return;
  const uid = state.user.id;
  const { data } = await sb.from("dms")
    .select("id,sender_id,recipient_id,content,created_at")
    .or(`sender_id.eq.${uid},recipient_id.eq.${uid}`)
    .order("created_at", { ascending: false })
    .limit(200);
  const seen = {};
  const others = [];
  (data || []).forEach((m) => {
    const other = m.sender_id === uid ? m.recipient_id : m.sender_id;
    if (!seen[other]) { seen[other] = m; others.push(other); }
  });
  box.innerHTML = "";
  if (!others.length) { box.innerHTML = `<div class="chart-empty" style="padding:20px">Aucune conversation.<br>Tape « Nouveau » pour écrire à quelqu'un.</div>`; return; }
  const { data: profs } = await sb.from("profiles").select("id,pseudo,avatar_url,level").in("id", others);
  const pmap = {}; (profs || []).forEach((p) => { pmap[p.id] = p; });
  others.forEach((oid) => {
    const p = pmap[oid] || { pseudo: "Membre" };
    const last = seen[oid];
    const row = document.createElement("button");
    row.className = "room-btn dm-convo" + (state.dmWith === oid ? " active" : "");
    const av = document.createElement("span"); av.className = "dm-cv-av"; applyAvatar(av, p.pseudo, oid, p.avatar_url, p.level);
    const info = document.createElement("div"); info.style.flex = "1"; info.style.minWidth = "0";
    const nm = document.createElement("div"); nm.className = "nm"; nm.textContent = p.pseudo;
    const pv = document.createElement("div"); pv.className = "dm-cv-prev"; pv.textContent = (last.sender_id === uid ? "Toi : " : "") + last.content;
    info.appendChild(nm); info.appendChild(pv);
    row.appendChild(av); row.appendChild(info);
    row.onclick = () => openConversation(oid, p);
    box.appendChild(row);
  });
}

async function openMemberPicker() {
  state.dmWith = null;
  $("#dm-title").textContent = "Nouveau message";
  $("#dm-sub").textContent = "Choisis un membre";
  $("#dm-composer").style.display = "none";
  const box = $("#dm-messages");
  box.innerHTML = `<div class="chart-empty">Chargement…</div>`;
  const { data } = await sb.from("profiles").select("id,pseudo,avatar_url,level").neq("id", state.user.id).order("pseudo").limit(100);
  box.innerHTML = "";
  (data || []).forEach((p) => {
    const row = document.createElement("button");
    row.className = "room-btn dm-pick";
    const av = document.createElement("span"); av.className = "dm-cv-av"; applyAvatar(av, p.pseudo, p.id, p.avatar_url, p.level);
    const nm = document.createElement("span"); nm.className = "nm"; nm.textContent = p.pseudo;
    row.appendChild(av); row.appendChild(nm);
    row.onclick = () => openConversation(p.id, p);
    box.appendChild(row);
  });
  if (!data || !data.length) box.innerHTML = `<div class="chart-empty">Aucun autre membre pour l'instant.</div>`;
}

async function openConversation(otherId, prof) {
  state.dmWith = otherId;
  const uid = state.user.id;
  $("#dm-title").textContent = prof.pseudo;
  $("#dm-sub").textContent = "Conversation privée";
  $("#dm-composer").style.display = "flex";
  $$(".dm-convo").forEach((b) => b.classList.remove("active"));
  const box = $("#dm-messages");
  box.innerHTML = `<div class="chat-empty">Chargement…</div>`;
  const { data } = await sb.from("dms")
    .select("*")
    .or(`and(sender_id.eq.${uid},recipient_id.eq.${otherId}),and(sender_id.eq.${otherId},recipient_id.eq.${uid})`)
    .order("created_at", { ascending: true })
    .limit(200);
  box.innerHTML = "";
  if (!data || !data.length) box.innerHTML = `<div class="chat-empty">Aucun message. Dis bonjour 🤍</div>`;
  else data.forEach((m) => appendDM(m));
  loadConversations();
}

function appendDM(m) {
  const box = $("#dm-messages");
  if ($(".chat-empty", box)) box.innerHTML = "";
  const mine = m.sender_id === state.user.id;
  const wrap = document.createElement("div");
  wrap.className = "msg" + (mine ? " mine" : "");
  const bubble = document.createElement("div");
  bubble.className = "bubble";
  bubble.textContent = m.content;
  const meta = document.createElement("div"); meta.className = "meta";
  meta.textContent = (mine ? "Toi" : "") + " " + fmtTime(m.created_at);
  wrap.appendChild(meta); wrap.appendChild(bubble);
  box.appendChild(wrap);
  box.scrollTop = box.scrollHeight;
  return wrap;
}

async function sendDM(e) {
  e.preventDefault();
  if (!state.dmWith) return;
  const input = $("#dm-input");
  const content = input.value.trim();
  if (!content) return;
  input.value = ""; input.style.height = "48px";
  const m = { sender_id: state.user.id, recipient_id: state.dmWith, content };
  const bubble = appendDM({ ...m, created_at: new Date().toISOString() });
  const { error } = await sb.from("dms").insert(m);
  if (error) {
    if (bubble) bubble.remove();
    input.value = content;
    toast("Message non envoyé.");
  } else loadConversations();
}
