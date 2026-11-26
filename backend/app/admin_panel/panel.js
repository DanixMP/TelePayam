const $ = (selector) => document.querySelector(selector);
const apiRoot = new URL("../api/v1/", import.meta.url);
let phone = "";
let session = null; // This tab only: never persist admin credentials in browser storage.
let registrations = null;
let busy = false;

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
    throw new Error("Could not reach the server. Check your connection and try again.");
  }
  if (response.status === 204) return;
  if (!response.ok) {
    const { error } = await response.json().catch(() => ({}));
    throw Object.assign(new Error(error?.detail || "The request failed. Please try again."), {
      status: response.status, code: error?.code,
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
    throw Object.assign(new Error("Only an active administrator can access this panel."), { status: 403 });
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
  $("#dev-code").textContent = "";
  $("#dev-code").hidden = true;
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
  $("#error").textContent = $("#status").textContent = "";
  document.querySelectorAll("button").forEach((button) => { button.disabled = true; });
  document.querySelectorAll("input").forEach((input) => { input.readOnly = true; });
  try {
    focusAfter = await action();
  } catch (error) {
    let message = error.message;
    if (session && [401, 403].includes(error.status)) {
      const old = session;
      signedOut();
      void revoke(old).catch(() => {});
      message = "Your admin session has ended. Sign in again.";
    } else if (["otp_expired", "otp_locked"].includes(error.code)) {
      message = "This SMS code can no longer be used. Request a new code and try again.";
    }
    $("#error").textContent = message;
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
  if (result.development_code) {
    $("#dev-code").textContent = `Development SMS code: ${result.development_code}`;
    $("#dev-code").hidden = false;
  }
  $("#status").textContent = "A new SMS code was requested.";
}

function renderQueue(items) {
  registrations = items;
  const rows = $("#rows");
  rows.replaceChildren();
  $("#count").hidden = items === null;
  $("#count").textContent = items?.length ?? "";
  $("#requests").hidden = !items?.length;
  $("#queue-state").hidden = Boolean(items?.length);
  $("#queue-state").textContent = items === null ? "Loading registrations…" : "No pending registrations.";
  for (const item of items || []) {
    const row = $("#request-row").content.cloneNode(true);
    const name = [item.first_name, item.last_name].filter(Boolean).join(" ") || item.university_id;
    row.querySelector(".student-name").textContent = name;
    row.querySelector(".university-id").textContent = item.university_id;
    row.querySelector(".department").textContent = item.department;
    row.querySelector(".degree").textContent = item.degree;
    row.querySelector(".national-id").textContent = item.national_id_masked;
    const button = row.querySelector(".approve");
    button.setAttribute("aria-label", `Approve ${name}`);
    button.addEventListener("click", () => run(() => approve(item.id, name, button)));
    rows.append(row);
  }
}

async function loadQueue() {
  try {
    renderQueue(await adminApi("approvals"));
  } catch (error) {
    if (registrations === null) $("#queue-state").textContent = "Use Refresh list to load registrations again.";
    throw error;
  }
}

async function approve(id, name, button) {
  const index = registrations.findIndex((item) => item.id === id);
  button.textContent = "Approving…";
  try {
    await adminApi(`approvals/${encodeURIComponent(id)}`, { action: "approve" });
    renderQueue(registrations.filter((item) => item.id !== id));
    $("#status").textContent = `${name} was approved. The student account is active.`;
  } catch (error) {
    if (error.code !== "approval_not_found") throw error;
    await loadQueue();
    $("#status").textContent = "This registration is no longer pending. The list has been refreshed.";
  } finally {
    button.textContent = "Approve";
  }
  const remaining = $("#rows").querySelectorAll("th[scope=row]");
  return remaining[Math.min(index, remaining.length - 1)] ?? $("#refresh");
}

$("#phone-form").addEventListener("submit", (event) => { event.preventDefault(); run(sendCode); });
$("#resend").addEventListener("click", () => run(sendCode));
$("#change-phone").addEventListener("click", () => run(() => showCodes(false)));
$("#code-form").addEventListener("submit", (event) => {
  event.preventDefault();
  run(async () => {
    await acceptSession(await api("auth/otp/verify", { body: {
      phone, code: $("#sms").value,
      platform: "web", device_name: "Admin panel",
    } }));
    showCodes(false);
    $("#phone-form").reset();
    $("#sign-in").hidden = true;
    $("#queue").hidden = $("#sign-out").hidden = false;
    $(".queue-surface").before($("#feedback"));
    $("#queue-title").focus();
    await loadQueue();
  });
});
$("#add-admin-form").addEventListener("submit", (event) => {
  event.preventDefault();
  run(async () => {
    const added = await adminApi("admins", { phone: $("#new-admin-phone").value.trim() });
    $("#add-admin-form").reset();
    $("#status").textContent = `Admin added: ${added.phone}. They can now sign in with their SMS code.`;
  });
});
$("#refresh").addEventListener("click", () => run(async () => {
  await loadQueue();
  $("#status").textContent = "Registration list refreshed.";
}));
$("#sign-out").addEventListener("click", () => run(async () => {
  const old = session;
  signedOut();
  try {
    await revoke(old);
    $("#status").textContent = "Signed out.";
  } catch {
    $("#error").textContent = "Signed out of this tab. The server could not confirm sign-out.";
  }
}));
window.addEventListener("pagehide", () => {
  if (session) void revoke(session, true).catch(() => {});
  signedOut();
  $("#status").textContent = $("#error").textContent = "";
});

// Accept Persian and Arabic numerals from mobile keyboards before HTML validation.
document.querySelectorAll("input").forEach((input) => input.addEventListener("input", () => {
  const ascii = input.value.replace(/[۰-۹٠-٩]/g, (digit) => String(digit.charCodeAt(0) & 15));
  if (ascii !== input.value) input.value = ascii;
}));
