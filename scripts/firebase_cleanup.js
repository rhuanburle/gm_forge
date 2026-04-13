#!/usr/bin/env node
/**
 * GM Forge — Firebase Full Cleanup Script
 *
 * Usa as credenciais do `firebase login` — sem service account.
 *
 * Apaga:
 *   - Firestore: coleções /users e /public_pages  (via firebase CLI)
 *   - Storage:   todos os arquivos do bucket      (via Firebase Storage REST API)
 *
 * Uso:
 *   node firebase_cleanup.js           ← apaga tudo
 *   node firebase_cleanup.js --dry-run ← só lista, não apaga
 */

const https   = require('https');
const { spawnSync } = require('child_process');
const os      = require('os');
const path    = require('path');
const fs      = require('fs');

// ─── Config ──────────────────────────────────────────────────────────────────
const PROJECT_ID     = 'quest-script';
const STORAGE_BUCKET = 'quest-script.firebasestorage.app';
const DRY_RUN        = process.argv.includes('--dry-run');

// ─── OAuth token via firebase-tools ──────────────────────────────────────────
function getStoredTokens() {
  const p = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(p)) { console.error('❌ Execute `firebase login` primeiro.'); process.exit(1); }
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  return cfg?.tokens ?? {};
}

async function getAccessToken() {
  const tokens = getStoredTokens();
  const { refresh_token, access_token, expires_at } = tokens;
  if (access_token && expires_at && Date.now() < expires_at - 300_000) return access_token;

  console.log('🔄 Renovando token OAuth...');
  const body = new URLSearchParams({
    client_id:     '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8yncnhiIwrA',
    grant_type:    'refresh_token',
    refresh_token,
  }).toString();

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        const j = JSON.parse(d);
        if (j.error) return reject(new Error(`OAuth: ${j.error_description}`));
        resolve(j.access_token);
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ─── Firebase Storage REST API ────────────────────────────────────────────────
function storageRequest(method, urlPath, token) {
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'firebasestorage.googleapis.com',
      path: urlPath,
      method,
      headers: { Authorization: `Bearer ${token}` },
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        if (res.statusCode === 204 || res.statusCode === 200 && !d) return resolve(null);
        if (res.statusCode >= 400) return reject(new Error(`Storage API ${res.statusCode}: ${d}`));
        resolve(d ? JSON.parse(d) : null);
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function listAllStorageFiles(token) {
  const files = [];
  const bucket = encodeURIComponent(STORAGE_BUCKET);
  let pageToken = '';
  do {
    const qs = pageToken ? `?pageToken=${encodeURIComponent(pageToken)}` : '';
    const res = await storageRequest('GET', `/v0/b/${bucket}/o${qs}`, token);
    if (res?.items) files.push(...res.items);
    pageToken = res?.nextPageToken ?? '';
  } while (pageToken);
  return files;
}

async function deleteStorageFile(name, token) {
  const bucket = encodeURIComponent(STORAGE_BUCKET);
  const file   = encodeURIComponent(name);
  await storageRequest('DELETE', `/v0/b/${bucket}/o/${file}`, token);
}

// ─── Firestore via firebase CLI ───────────────────────────────────────────────
function cleanFirestore() {
  console.log('\n🔥 Firestore\n');

  if (DRY_RUN) {
    console.log('  [DRY RUN] Seria executado:');
    console.log(`  firebase firestore:delete --all-collections --project ${PROJECT_ID} --force`);
    console.log('');
    return;
  }

  console.log('→ Apagando todas as coleções...');
  const result = spawnSync('firebase', [
    'firestore:delete',
    '--all-collections',
    '--project', PROJECT_ID,
    '--force',
  ], { encoding: 'utf8', stdio: 'inherit' });

  if (result.status !== 0) {
    console.warn('⚠️  Possível erro no firebase firestore:delete');
  } else {
    console.log('✅ Firestore limpo\n');
  }
}

// ─── Storage cleanup ──────────────────────────────────────────────────────────
async function cleanStorage(token) {
  console.log('\n📦 Storage\n');

  let files;
  try {
    files = await listAllStorageFiles(token);
  } catch (e) {
    if (e.message.includes('404')) {
      console.log('  Storage vazio ou bucket ainda não inicializado — nada a apagar.');
    } else {
      console.warn(`  ⚠️  Não foi possível listar arquivos: ${e.message}`);
    }
    return;
  }

  if (files.length === 0) {
    console.log('  Storage já está vazio.');
    return;
  }

  console.log(`  Encontrados ${files.length} arquivo(s):\n`);
  for (const file of files) {
    console.log(`  ${DRY_RUN ? '[DRY]' : '🗑 '} ${file.name}`);
    if (!DRY_RUN) await deleteStorageFile(file.name, token);
  }
  if (!DRY_RUN) console.log('\n  ✅ Storage limpo');
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════╗');
  console.log('║   GM Forge — Firebase Cleanup            ║');
  console.log(`║   Projeto: ${PROJECT_ID.padEnd(30)}║`);
  console.log(DRY_RUN
    ? '║   MODO: DRY RUN (nada será apagado)      ║'
    : '║   ⚠️  EXECUÇÃO REAL — dados serão apagados ║');
  console.log('╚══════════════════════════════════════════╝');

  if (!DRY_RUN) {
    console.log('\nComeçando em 3 segundos... Ctrl+C para cancelar.\n');
    await new Promise(r => setTimeout(r, 3000));
  }

  const token = await getAccessToken();
  const email = getStoredTokens().id_token
    ? JSON.parse(Buffer.from(getStoredTokens().id_token.split('.')[1], 'base64').toString()).email
    : 'rhuanburlerb@gmail.com';
  console.log(`🔑 Autenticado como: ${email}`);

  cleanFirestore();
  await cleanStorage(token);

  console.log('\n══════════════════════════════════════════');
  console.log(`✅ Concluído${DRY_RUN ? ' (dry run)' : ''}!`);
  console.log('══════════════════════════════════════════\n');
}

main().catch(err => {
  console.error('\n❌ Erro:', err.message || err);
  process.exit(1);
});
