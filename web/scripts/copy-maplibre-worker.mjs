// Copies the MapLibre GL worker files into public/ so they are served as
// static assets. Required for Turbopack/Next.js: the bundler does not emit
// the worker's sibling files, so the worker must be pointed at /maplibre/
// explicitly via setWorkerUrl(). See MapLibre ESM/Turbopack installation docs.
import {copyFileSync, mkdirSync} from 'node:fs';
import {createRequire} from 'node:module';
import path from 'node:path';

const dist = path.join(path.dirname(createRequire(import.meta.url).resolve('maplibre-gl/package.json')), 'dist');
const dest = path.join(process.cwd(), 'public', 'maplibre');

mkdirSync(dest, {recursive: true});
for (const file of ['maplibre-gl-worker.mjs', 'maplibre-gl-shared.mjs']) {
    copyFileSync(path.join(dist, file), path.join(dest, file));
    console.log(`copied ${file} -> public/maplibre/`);
}