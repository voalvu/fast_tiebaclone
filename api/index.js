import wasmModule from './tieba.mjs';

export default async function handler(request) {
  try {
    // Set a complete location object
    const url = new URL(request.url);
    globalThis.location = {
      href: url.href,
      protocol: url.protocol,
      host: url.host,
      hostname: url.hostname,
      port: url.port,
      pathname: url.pathname,
      search: url.search,
      hash: url.hash,
      origin: url.origin
    };
    console.log(url)

    const { method } = request;
    console.log(method)

    const body = method === 'POST' ? await request.text() : null;
    console.log(body)
    // Initialize WASM module
    const module = await wasmModule({ noInitialRun: true });
    const handleRequest = module.cwrap('handle_request', 'string', ['string', 'string']);
    const response = handleRequest(method.toUpperCase(), body || "");
    console.log(module,handleRequest,response)
    // Parse response (assuming your WASM returns HTTP-like response)
    const [headersSection, content] = response.split('\r\n\r\n');
    const headerLines = headersSection.split('\r\n');
    const statusLine = headerLines[0];
    const headers = headerLines.slice(1).filter(Boolean).map(h => h.split(': '));
    const statusCode = parseInt(statusLine.split(' ')[1], 10);
    console.log(headersSection,content,headerLines,statusLine,headers,statusCode)
    return new Response(content || "", {
      status: statusCode,
      headers: Object.fromEntries(headers)
    });
  } catch (error) {
    console.error('Handler error:', error, 'request.url:', request.url);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
}

export const config = {
  runtime: 'edge'
};