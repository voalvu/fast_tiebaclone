import wasmModule from './tieba.mjs';

export default async function handler(request) {
  try {
    // Mock the location object to prevent 'href' errors
    globalThis.location = { href: request.url };

    const { method } = request;
    const body = method === 'POST' ? await request.text() : null;

    // Initialize WASM module
    const module = await wasmModule({
      noInitialRun: true
    });

    const handleRequest = module.cwrap('handle_request', 'string', ['string', 'string']);
    const response = handleRequest(method.toUpperCase(), body || "");

    // Parse the response correctly
    const [headersSection, content] = response.split('\r\n\r\n');
    const headerLines = headersSection.split('\r\n');
    const statusLine = headerLines[0]; // e.g., "HTTP/1.1 200 OK"
    const headers = headerLines.slice(1).filter(Boolean).map(h => h.split(': '));
    const statusCode = parseInt(statusLine.split(' ')[1], 10); // Extract "200" from "HTTP/1.1 200 OK"

    return new Response(content || "", {
      status: statusCode,
      headers: Object.fromEntries(headers)
    });
  } catch (error) {
    console.error('Handler error:', error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
}

export const config = {
  runtime: 'edge'
};