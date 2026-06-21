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
  }
  sb.auth.onAuthStateChange((_evt, session) => {
    if (!session) location.reload();
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

  $("#auth").style.display = "none";
  $("#app").style.display = "flex";

  $("#me-name").textContent = state.profile.pseudo;
  $("#me-av").textContent = state.profile.avatar_emoji || "🌙";

  initNav();
  await initChat();
  await initDashboard();
  initProfile();
}

async function fetchProfile(id) {
  const { data } = await sb.from("profiles").select("*").eq("id", id).maybeSingle();
  return data;
}

/* ============================================================
   Navigation entre vues
============================================================ */
function initNav() {
  $$(".tabsnav button").forEach((b) => {
    b.addEventListener("click", () => {
      $$(".tabsnav button").forEach((x) => x.classList.remove("active"));
      b.classList.add("active");
      $$(".view").forEach((v) => v.classList.remove("active"));
      $("#view-" + b.dataset.view).classList.add("active");
      if (b.dataset.view === "dash") loadBadges();
    });
  });
}

/* ============================================================
   SALONS DE CHAT (temps réel)
============================================================ */
async function initChat() {
  const { data: rooms } = await sb.from("rooms").select("*").order("sort", { ascending: true });
  state.rooms = rooms || [];
  const list = $("#rooms-list");
  list.innerHTML = "";
  state.rooms.forEach((room) => {
    const btn = document.createElement("button");
    btn.className = "room-btn";
    btn.dataset.id = room.id;
    btn.innerHTML = `<span class="em"></span><span class="nm"></span>`;
    btn.querySelector(".em").textContent = room.emoji || "💬";
    btn.querySelector(".nm").textContent = room.name;
    btn.addEventListener("click", () => selectRoom(room));
    list.appendChild(btn);
  });
  if (state.rooms.length) selectRoom(state.rooms[0]);

  startPresence();

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
  $$(".room-btn").forEach((b) => b.classList.toggle("active", b.dataset.id === room.id));
  $("#room-title").textContent = (room.emoji || "💬") + "  " + room.name;
  $("#room-desc").textContent = room.description || "";

  const box = $("#messages");
  box.innerHTML = `<div class="chat-empty">Chargement…</div>`;

  const { data: msgs } = await sb
    .from("messages")
    .select("id, content, created_at, user_id, profiles(pseudo, avatar_emoji)")
    .eq("room_id", room.id)
    .order("created_at", { ascending: true })
    .limit(100);

  box.innerHTML = "";
  if (!msgs || !msgs.length) {
    box.innerHTML = `<div class="chat-empty">Aucun message pour l'instant.<br>Sois la première voix douce de ce salon. 🌙</div>`;
  } else {
    msgs.forEach(renderMessage);
    scrollChat();
  }

  // (Re)souscription temps réel
  if (state.roomChannel) sb.removeChannel(state.roomChannel);
  state.roomChannel = sb
    .channel("room:" + room.id)
    .on(
      "postgres_changes",
      { event: "INSERT", schema: "public", table: "messages", filter: "room_id=eq." + room.id },
      async (payload) => {
        const m = payload.new;
        // Récupère le pseudo de l'auteur
        let pseudo = "Membre", emoji = "🌙";
        if (m.user_id === state.user.id) {
          pseudo = state.profile.pseudo; emoji = state.profile.avatar_emoji;
        } else {
          const { data: p } = await sb.from("profiles").select("pseudo, avatar_emoji").eq("id", m.user_id).maybeSingle();
          if (p) { pseudo = p.pseudo; emoji = p.avatar_emoji; }
        }
        if ($(".chat-empty", box)) box.innerHTML = "";
        renderMessage({ ...m, profiles: { pseudo, avatar_emoji: emoji } });
        scrollChat();
      }
    )
    .subscribe();
}

function renderMessage(m) {
  const box = $("#messages");
  const mine = m.user_id === state.user.id;
  const wrap = document.createElement("div");
  wrap.className = "msg" + (mine ? " mine" : "");
  wrap.dataset.uid = m.user_id;
  const prev = box.lastElementChild;
  if (prev && prev.dataset && prev.dataset.uid === m.user_id) wrap.classList.add("grouped");
  const who = (m.profiles && m.profiles.pseudo) || "Membre";
  const meta = document.createElement("div");
  meta.className = "meta";
  const av = document.createElement("span");
  av.className = "av";
  av.style.background = colorFromString(m.user_id);
  av.textContent = (who[0] || "?").toUpperCase();
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
  box.appendChild(wrap);
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
  const input = $("#msg-input");
  const content = input.value.trim();
  if (!content || !state.currentRoom) return;
  input.value = "";
  input.style.height = "46px";
  const { error } = await sb.from("messages").insert({
    room_id: state.currentRoom.id,
    user_id: state.user.id,
    content,
  });
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
  setQuote();
  initBreathing();

  await loadChallenge();
  await loadRoadmap();
  await loadMood();
  await loadBadges();
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
    toast("Humeur enregistrée 🌙");
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
    { e: "👋", n: "Première parole", d: "1er message", ok: msgC >= 1 },
    { e: "💬", n: "Voix de la nuit", d: "10 messages", ok: msgC >= 10 },
    { e: "📈", n: "À l'écoute", d: "3 humeurs notées", ok: moodC >= 3 },
    { e: "🌗", n: "Sept nuits", d: "7 humeurs notées", ok: moodC >= 7 },
    { e: "🔥", n: "Premier défi", d: "1 défi relevé", ok: chC >= 1 },
    { e: "🏆", n: "Persévérance", d: "5 défis relevés", ok: chC >= 5 },
    { e: "🧭", n: "En route", d: "1 objectif atteint", ok: rmDone >= 1 },
    { e: "🌙", n: "Présent·e", d: "Tu es là, ce soir", ok: true },
  ];
  const box = $("#badges");
  box.innerHTML = "";
  defs.forEach((b) => {
    const el = document.createElement("div");
    el.className = "badge " + (b.ok ? "earned" : "locked");
    el.innerHTML = `<span class="be"></span><span class="bn"></span><span class="bd"></span>`;
    el.querySelector(".be").textContent = b.e;
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
    list.innerHTML = `<div class="chart-empty">Ajoute un premier objectif, même tout petit. 🌱</div>`;
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
    chart.innerHTML = `<div class="chart-empty">Enregistre ton humeur pour voir ta courbe apparaître. 📈</div>`;
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
    await sb.auth.signOut();
    location.href = "index.html";
  });
}
