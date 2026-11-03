#!/usr/bin/env node

import { readFileSync } from 'node:fs'
import { createPrivateKey, sign } from 'node:crypto'

const argumentsList = process.argv.slice(2)

function option(name) {
  const index = argumentsList.indexOf(name)
  return index >= 0 ? argumentsList[index + 1] : undefined
}

function requiredOption(name) {
  const value = option(name)
  if (!value || value.startsWith('--')) {
    throw new Error(`Missing required option: ${name}`)
  }
  return value
}

function base64UrlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url')
}

function printUsage() {
  process.stdout.write(`
Generate an Apple OAuth client secret locally.

Usage:
  node scripts/generate_apple_client_secret.mjs \\
    --team-id APPLE_TEAM_ID \\
    --key-id APPLE_KEY_ID \\
    --client-id com.nazrinapp.petani.auth \\
    --private-key /absolute/path/AuthKey_XXXXXXXXXX.p8

Optional:
  --days NUMBER   Validity in days (default: 180, maximum: 180)

The generated JWT is printed to stdout. Never commit or share the .p8 file.
`)
}

if (argumentsList.includes('--help') || argumentsList.includes('-h')) {
  printUsage()
  process.exit(0)
}

try {
  const teamId = requiredOption('--team-id')
  const keyId = requiredOption('--key-id')
  const clientId = requiredOption('--client-id')
  const privateKeyPath = requiredOption('--private-key')
  const validityDays = Number(option('--days') ?? '180')

  if (!Number.isInteger(validityDays) || validityDays < 1 || validityDays > 180) {
    throw new Error('--days must be a whole number between 1 and 180.')
  }

  const issuedAt = Math.floor(Date.now() / 1000)
  const header = { alg: 'ES256', kid: keyId }
  const payload = {
    iss: teamId,
    iat: issuedAt,
    exp: issuedAt + validityDays * 24 * 60 * 60,
    aud: 'https://appleid.apple.com',
    sub: clientId,
  }
  const unsignedToken = `${base64UrlJson(header)}.${base64UrlJson(payload)}`
  const privateKey = createPrivateKey(readFileSync(privateKeyPath))
  const signature = sign('sha256', Buffer.from(unsignedToken), {
    key: privateKey,
    dsaEncoding: 'ieee-p1363',
  }).toString('base64url')

  process.stdout.write(`${unsignedToken}.${signature}\n`)
} catch (error) {
  process.stderr.write(`Unable to generate Apple client secret: ${error.message}\n`)
  printUsage()
  process.exit(1)
}
