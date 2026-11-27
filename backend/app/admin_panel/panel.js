import { translations } from "./translations.js";

const $ = (selector) => document.querySelector(selector);
const apiRoot = new URL("../api/v1/", import.meta.url);
const languageKey = "admin.locale";
const feedback = { status: [], error: [] };
let locale = "en";
let queueState = "loading";
let developmentCode = null;
let phone = "";
let session = null; // This tab only: never persist admin credentials in browser storage.
let registrations = null;
let busy = false;

function text(key, ...args) {
  const message = translations[locale][key];
  return typeof message === "function" ? message(...args) : message;
}

// Isolate names and identifiers interpolated into mixed-direction sentences.
const isolate = (value) => `\u2068${value}\u2069`;

function translate(root) {
  root.querySelectorAll("[data-i18n]").forEach((element) => {
    element.textContent = text(element.dataset.i18n);
  });
  root.querySelectorAll("[data-i18n-label]").forEach((element) => {
    element.setAttribute("aria-label", text(element.dataset.i18nLabel));
  });
}

function labelApproval(button, name) {
  button.setAttribute("aria-label", text(button.dataset.i18n === "approving" ? "approving" : "approveStudent", isolate(name)));
}

function degreeLabel(degree) {
  switch (degree.trim().toLowerCase()) {
    case "bsc": case "bachelor": case "bachelor’s": case "bachelor's": case "کارشناسی":
      return text("degreeBachelor");
    case "msc": case "master": case "master’s": case "master's": case "کارشناسی ارشد":
      return text("degreeMaster");
    case "phd": case "doctorate": case "دکتری":
      return text("degreeDoctorate");
    case "other": case "سایر":
      return text("degreeOther");
    default:
      return degree;
  }
}

function setFeedback(channel, ...message) {
  feedback[channel] = message;
  $(`#${channel}`).textContent = message.length ? text(...message) : "";
}

function renderDevelopmentCode() {
  $("#dev-code").hidden = !developmentCode;
  $("#dev-code").textContent = developmentCode ? text("developmentCode", isolate(developmentCode)) : "";
}

function renderQueueState() {
  $("#count").textContent = registrations === null ? "" : new Intl.NumberFormat(locale).format(registrations.length);
  $("#queue-state").textContent = text(queueState);
}

function applyLocale(value) {
  locale = value === "fa" ? "fa" : "en";
  document.documentElement.lang = locale;
  document.documentElement.dir = locale === "fa" ? "rtl" : "ltr";
  document.title = text("pageTitle");
  $("#language").value = locale;
  translate(document);
  Array.from($("#rows").rows).forEach((row, index) => {
    row.querySelector(".degree").textContent = degreeLabel(registrations[index].degree);
    labelApproval(row.querySelector(".approve"), row.querySelector(".student-name").textContent);
  });
  renderDevelopmentCode();
  renderQueueState();
  setFeedback("status", ...feedback.status);
  setFeedback("error", ...feedback.error);
}

function errorKey(error) {
  switch (error.code) {
    case "network_error": return "networkError";
    case "otp_expired":
    case "otp_locked": return "codeUnavailable";
    case "otp_invalid": return "incorrectCode";
    case "otp_rate_limited": return "rateLimited";
    case "invalid_phone": return "invalidPhone";
    case "phone_exists": return "phoneExists";
    case "account_blocked":
    case "admin_access_required": return "adminAccess";
    case "totp_invalid":
    case "totp_setup_required": return "authenticatorRequired";
    default: return error.status === 429 ? "rateLimited" : "requestFailed";
  }
}

async function api(path, { body, token, keepalive = false } = {}) {
  const headers = { Accept: "application/json" };
  if (body) headers["Content-Type"] = "application/json";
  if (token) headers.Authorization = `Bearer ${token}`;
  let response;
  try {
    response = await fetch(new URL(path, apiRoot), {
      method: body ? "POST" : "GET", headers, body: JSON.stringify(body),
      credentials: "omit", cache: "no-store", keepalive,
    });
  } catch {
    throw Object.assign(new Error("network_error"), { code: "network_error" });
  }
  if (response.status === 204) return;
  if (!response.ok) {
    const result = await response.json().catch(() => null);
    const code = result?.error?.code;
    throw Object.assign(new Error(code), {
      status: response.status, code,
    });
  }
  return response.json();
}

function revoke(pair, keepalive = false) {
  return api("auth/logout", {
    token: pair.access_token, body: { refresh_token: pair.refresh_token }, keepalive,
  });
}

async function acceptSession(pair) {
  if (!["admin", "super_admin"].includes(pair.user.role) || pair.user.status !== "active") {
    await revoke(pair).catch(() => {});
    throw Object.assign(new Error("admin_access_required"), { status: 403, code: "admin_access_required" });
  }
  session = pair;
  $("#manage-admins").hidden = pair.user.role !== "super_admin";
}

async function adminApi(path, body) {
  const send = () => api(`admin/${path}`, { body, token: session.access_token });
  try {
    return await send();
  } catch (error) {
    if (error.status !== 401) throw error;
  }
  // UI actions are serialized so two requests cannot reuse a rotating refresh token.
  await acceptSession(await api("auth/refresh", { body: { refresh_token: session.refresh_token } }));
  return send();
}

function showCodes(show) {
  $("#phone-form").hidden = show;
  $("#code-form").hidden = !show;
  $(show ? "#phone-step" : "#codes-step").removeAttribute("aria-current");
  $(show ? "#codes-step" : "#phone-step").setAttribute("aria-current", "step");
  $("#code-form").reset();
  developmentCode = null;
  renderDevelopmentCode();
  $("#destination").textContent = show ? phone : "";
  $(show ? "#sms" : "#phone").focus();
}

function signedOut() {
  session = null;
  phone = "";
  renderQueue(null);
  $("#queue").hidden = true;
  $("#sign-out").hidden = true;
  $("#manage-admins").hidden = true;
  $("#manage-admins").open = false;
  $("#add-admin-form").reset();
  $("#sign-in").hidden = false;
  $("#sign-in").after($("#feedback"));
  $("#phone-form").reset();
  showCodes(false);
}

async function run(action) {
  if (busy) return;
  busy = true;
  const trigger = document.activeElement;
  let focusAfter;
  setFeedback("error");
  setFeedback("status");
  document.querySelectorAll("button").forEach((button) => { button.disabled = true; });
  document.querySelectorAll("input").forEach((input) => { input.readOnly = true; });
  try {
    focusAfter = await action();
  } catch (error) {
    let message = errorKey(error);
    if (session && [401, 403].includes(error.status)) {
      const old = session;
      signedOut();
      void revoke(old).catch(() => {});
      message = "sessionEnded";
    }
    setFeedback("error", message);
    if (document.activeElement === document.body && trigger instanceof HTMLButtonElement && trigger.isConnected) {
      focusAfter = trigger;
    }
  } finally {
    busy = false;
    document.querySelectorAll("button").forEach((button) => { button.disabled = false; });
    document.querySelectorAll("input").forEach((input) => { input.readOnly = false; });
    focusAfter?.focus();
  }
}

async function sendCode() {
  phone = $("#phone").value.trim();
  const result = await api("auth/otp/request", { body: { phone } });
  showCodes(true);
  developmentCode = result.development_code;
  renderDevelopmentCode();
  setFeedback("status", "codeRequested");
}

function renderQueue(items) {
  registrations = items;
  const rows = $("#rows");
  rows.replaceChildren();
  $("#count").hidden = items === null;
  $("#requests").hidden = !items?.length;
  $("#queue-state").hidden = Boolean(items?.length);
  queueState = items === null ? "loading" : "noPending";
  renderQueueState();
  for (const item of items || []) {
    const row = $("#request-row").content.cloneNode(true);
    const name = [item.first_name, item.last_name].filter(Boolean).join(" ") || item.university_id;
    row.querySelector(".student-name").textContent = name;
    row.querySelector(".university-id").textContent = item.university_id;
    row.querySelector(".department").textContent = item.department;
    row.querySelector(".degree").textContent = degreeLabel(item.degree);
    row.querySelector(".national-id").textContent = item.national_id_masked;
    const button = row.querySelector(".approve");
    translate(row);
    labelApproval(button, name);
    button.addEventListener("click", () => run(() => approve(item.id, name, button)));
    rows.append(row);
  }
}

async function loadQueue() {
  try {
    renderQueue(await adminApi("approvals"));
  } catch (error) {
    if (registrations === null) {
      queueState = "retryQueue";
      renderQueueState();
    }
    throw error;
  }
}

async function approve(id, name, button) {
  const index = registrations.findIndex((item) => item.id === id);
  button.dataset.i18n = "approving";
  button.textContent = text("approving");
  labelApproval(button, name);
  try {
    await adminApi(`approvals/${encodeURIComponent(id)}`, { action: "approve" });
    renderQueue(registrations.filter((item) => item.id !== id));
    setFeedback("status", "approved", isolate(name));
  } catch (error) {
    if (error.code !== "approval_not_found") throw error;
    await loadQueue();
    setFeedback("status", "approvalReviewed");
  } finally {
    button.dataset.i18n = "approve";
    button.textContent = text("approve");
    labelApproval(button, name);
  }
  const remaining = $("#rows").querySelectorAll("th[scope=row]");
  return remaining[Math.min(index, remaining.length - 1)] ?? $("#refresh");
}

function submit(form, input, invalidMessage, action) {
  form.noValidate = true;
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    if (busy) return;
    if (!input.validity.valid || !input.value.trim()) {
      setFeedback("status");
      setFeedback("error", invalidMessage);
      input.focus();
      return;
    }
    run(action);
  });
}

submit($("#phone-form"), $("#phone"), "invalidPhone", sendCode);
$("#resend").addEventListener("click", () => run(sendCode));
$("#change-phone").addEventListener("click", () => run(() => showCodes(false)));
submit($("#code-form"), $("#sms"), "invalidCode", async () => {
  await acceptSession(await api("auth/otp/verify", { body: {
    phone, code: $("#sms").value,
    platform: "web", device_name: text("adminPanel"),
  } }));
  showCodes(false);
  $("#phone-form").reset();
  $("#sign-in").hidden = true;
  $("#queue").hidden = $("#sign-out").hidden = false;
  $(".queue-surface").before($("#feedback"));
  $("#queue-title").focus();
  await loadQueue();
});
submit($("#add-admin-form"), $("#new-admin-phone"), "invalidPhone", async () => {
  const added = await adminApi("admins", { phone: $("#new-admin-phone").value.trim() });
  $("#add-admin-form").reset();
  setFeedback("status", "adminAdded", isolate(added.phone));
});
$("#refresh").addEventListener("click", () => run(async () => {
  await loadQueue();
  setFeedback("status", "refreshed");
}));
$("#sign-out").addEventListener("click", () => run(async () => {
  const old = session;
  signedOut();
  try {
    await revoke(old);
    setFeedback("status", "signedOut");
  } catch {
    setFeedback("error", "unconfirmedSignOut");
  }
}));
window.addEventListener("pagehide", () => {
  if (session) void revoke(session, true).catch(() => {});
  signedOut();
  setFeedback("status");
  setFeedback("error");
});

// Accept Persian and Arabic numerals from mobile keyboards before HTML validation.
document.querySelectorAll("input").forEach((input) => input.addEventListener("input", () => {
  const ascii = input.value.replace(/[۰-۹٠-٩]/g, (digit) => String(digit.charCodeAt(0) & 15));
  if (ascii !== input.value) input.value = ascii;
}));

let savedLocale;
try { savedLocale = localStorage.getItem(languageKey); } catch { /* Storage may be disabled. */ }
applyLocale(savedLocale);
$("#language").hidden = false;
$("#language").addEventListener("change", (event) => {
  applyLocale(event.target.value);
  try { localStorage.setItem(languageKey, locale); } catch { /* Apply in this tab anyway. */ }
});
