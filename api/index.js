import wasmModule from './tieba.mjs';

export default async function handler(request) {
  try {
    const { method } = request;
    const body = method === 'POST' ? await request.text() : null;
    
    // Initialize WASM module with proper config
    const module = await wasmModule({
      noInitialRun: true,
      // Remove manual instantiateWasm and use default loader
      locateFile: (path) => {
        if(path.endsWith('.wasm')) {
          return new URL('./tieba.wasm', import.meta.url).href;
        }
        return path;
      }
    });

    // Create wrapped function with proper types
    const handleRequest = module.cwrap('handle_request', 'string', ['string', 'string']);
    
    // Process request
    const response = handleRequest(method.toUpperCase(), body || "");
    const [headers, content] = response.split('\r\n\r\n');
    
    return new Response(content || "", {
      headers: headers ? Object.fromEntries(
        headers.split('\r\n')
          .filter(Boolean)
          .map(h => {
            const [key, value] = h.split(': ');
            return [key.toLowerCase(), value];
          })
      ) : {}
    });
  } catch (error) {
    console.error('Handler error:', error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
}

export const config = {
  runtime: 'edge'
};