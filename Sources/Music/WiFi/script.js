/* Tools-Kit WiFi Transfer — Web Client */

const CHUNK_SIZE = 5 * 1024 * 1024; // 5 MB
const MAX_CONCURRENT = 2;

let session = null;
let queue = [];
let activeCount = 0;

// ─── Pairing ───────────────────────────────────────────────────────────────

async function pair() {
  const code = document.getElementById('pairing-code').value.trim();
  const errEl = document.getElementById('pair-error');
  errEl.classList.add('hidden');

  if (code.length !== 6) {
    showError(errEl, 'Please enter the 6-digit code.');
    return;
  }

  const btn = document.getElementById('pair-btn');
  btn.disabled = true;
  btn.textContent = 'Connecting…';

  try {
    const res = await fetch('/validate-code', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code }),
    });
    const data = await res.json();
    if (data.success) {
      session = data.session;
      document.getElementById('pairing-section').classList.add('hidden');
      document.getElementById('upload-section').classList.remove('hidden');
      initDropZone();
    } else {
      showError(errEl, 'Invalid code. Try again.');
      btn.disabled = false;
      btn.textContent = 'Connect';
    }
  } catch (e) {
    showError(errEl, 'Connection failed. Make sure you\'re on the same WiFi.');
    btn.disabled = false;
    btn.textContent = 'Connect';
  }
}

function showError(el, msg) {
  el.textContent = msg;
  el.classList.remove('hidden');
}

// ─── Drop Zone ──────────────────────────────────────────────────────────────

function initDropZone() {
  const zone = document.getElementById('drop-zone');
  const input = document.getElementById('file-input');

  zone.addEventListener('dragover', e => {
    e.preventDefault();
    zone.classList.add('drag-over');
  });
  zone.addEventListener('dragleave', () => zone.classList.remove('drag-over'));
  zone.addEventListener('drop', e => {
    e.preventDefault();
    zone.classList.remove('drag-over');
    addFiles([...e.dataTransfer.files]);
  });

  input.addEventListener('change', () => {
    addFiles([...input.files]);
    input.value = '';
  });
}

// ─── Queue Management ────────────────────────────────────────────────────────

function addFiles(files) {
  const allowed = new Set(['mp3', 'm4a', 'wav', 'aac', 'flac', 'zip']);
  for (const file of files) {
    const ext = file.name.split('.').pop().toLowerCase();
    if (!allowed.has(ext)) continue;
    const item = { id: crypto.randomUUID(), file, status: 'pending', progress: 0 };
    queue.push(item);
    renderItem(item);
  }
  document.getElementById('queue').classList.remove('hidden');
  updateSummary();
  drainQueue();
}

function drainQueue() {
  while (activeCount < MAX_CONCURRENT) {
    const next = queue.find(i => i.status === 'pending');
    if (!next) break;
    next.status = 'uploading';
    activeCount++;
    uploadFile(next).then(() => {
      activeCount--;
      updateSummary();
      drainQueue();
    });
  }
}

function clearCompleted() {
  queue = queue.filter(i => i.status === 'pending' || i.status === 'uploading');
  document.getElementById('queue-list').querySelectorAll('.queue-item[data-done="1"]')
    .forEach(el => el.remove());
  updateSummary();
}

function updateSummary() {
  const done  = queue.filter(i => i.status === 'done').length;
  const total = queue.length;
  document.getElementById('queue-summary').textContent =
    total ? `${done} / ${total} uploaded` : '';
}

// ─── Upload Logic ────────────────────────────────────────────────────────────

async function uploadFile(item) {
  const file = item.file;
  const totalChunks = Math.ceil(file.size / CHUNK_SIZE);

  try {
    // Upload chunks sequentially (reliable ordering)
    for (let i = 0; i < totalChunks; i++) {
      const chunk = file.slice(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE);
      await uploadChunkWithRetry(chunk, file.name, i, 3);
      item.progress = Math.round(((i + 1) / totalChunks) * 100);
      updateItemUI(item);
    }

    // Finalize
    const res = await fetchWithRetry('/finalize-upload', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session, filename: file.name, totalChunks }),
    }, 3);

    const data = await res.json();
    item.status = data.success ? 'done' : 'error';
  } catch (e) {
    item.status = 'error';
  }

  updateItemUI(item);
}

async function uploadChunkWithRetry(chunk, filename, index, maxRetries) {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const res = await fetch('/upload-chunk', {
        method: 'POST',
        headers: {
          'X-Session': session,
          'X-Filename': encodeURIComponent(filename),
          'X-Chunk-Index': String(index),
          'Content-Type': 'application/octet-stream',
        },
        body: chunk,
      });
      const data = await res.json();
      if (data.success) return;
      if (attempt === maxRetries) throw new Error(data.error || 'Upload failed');
    } catch (e) {
      if (attempt === maxRetries) throw e;
      await sleep(500 * (attempt + 1));
    }
  }
}

async function fetchWithRetry(url, opts, maxRetries) {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const res = await fetch(url, opts);
      return res;
    } catch (e) {
      if (attempt === maxRetries) throw e;
      await sleep(500 * (attempt + 1));
    }
  }
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ─── Rendering ────────────────────────────────────────────────────────────────

function renderItem(item) {
  const list = document.getElementById('queue-list');
  const el = document.createElement('div');
  el.className = 'queue-item';
  el.id = `qi-${item.id}`;
  el.innerHTML = `
    <div class="qi-header">
      <span class="qi-name">${escapeHTML(item.file.name)}</span>
      <span class="qi-size">${formatBytes(item.file.size)}</span>
      <span class="qi-status pending" id="qs-${item.id}">Pending</span>
    </div>
    <div class="progress-bar-wrap">
      <div class="progress-bar" id="qp-${item.id}"></div>
    </div>
  `;
  list.appendChild(el);
}

function updateItemUI(item) {
  const statusEl = document.getElementById(`qs-${item.id}`);
  const progressEl = document.getElementById(`qp-${item.id}`);
  const wrapEl = document.getElementById(`qi-${item.id}`);
  if (!statusEl) return;

  statusEl.className = `qi-status ${item.status}`;
  const labels = { pending: 'Pending', uploading: `${item.progress}%`, done: 'Done ✓', error: 'Error' };
  statusEl.textContent = labels[item.status] ?? item.status;

  if (progressEl) progressEl.style.width = `${item.progress}%`;
  if (item.status === 'done' || item.status === 'error') {
    if (wrapEl) wrapEl.dataset.done = '1';
  }
}

function escapeHTML(str) {
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1048576) return `${(bytes/1024).toFixed(1)} KB`;
  return `${(bytes/1048576).toFixed(1)} MB`;
}

// Allow Enter key in pairing input
document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('pairing-code').addEventListener('keydown', e => {
    if (e.key === 'Enter') pair();
  });
});
