import fs from 'fs';
import path from 'path';
import wasmModule from './tieba.mjs';

export default async function handler(request) {
  try {
    const { method } = request;
    const body = method === 'POST' ? await request.text() : null;

    // Define the path to the WASM file
    const wasmPath = path.join(__dirname, 'tieba.wasm');

    // Check if the WASM file exists
    if (!fs.existsSync(wasmPath)) {
      throw new Error('WASM file not found at ' + wasmPath);
    }

    // Initialize WASM module
    const module = await wasmModule({
      noInitialRun: true,
      locateFile: (file) => {
        if (file === 'tieba.wasm') {
          return wasmPath;
        }
        return file;
      }
    });

    const handleRequest = module.cwrap('handle_request', 'string', ['string', 'string']);
    const response = handleRequest(method.toUpperCase(), body || "");

    const [headers, content] = response.split('\r\n\r\n');
    return new Response(content || "", {
      headers: headers
        ? Object.fromEntries(
            headers
              .split('\r\n')
              .filter(Boolean)
              .map((h) => h.split(': '))
          )
        : {},
      status: response.startsWith('HTTP/1.1 200')
        ? 200
        : response.startsWith('HTTP/1.1 302')
        ? 302
        : 400
    });
  } catch (error) {
    console.error('Handler error:', error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
}

export const config = {
  runtime: 'edge'
};