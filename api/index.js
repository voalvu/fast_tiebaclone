import wasmModule from './tieba.mjs';

export default async function handler(request) {
  try {
    const { method } = request;
    const body = method === 'POST' ? await request.text() : null;
    
    // Initialize WASM module
    const module = await wasmModule({
      noInitialRun: true,
      instantiateWasm: (imports, success) => {
        WebAssembly.instantiate(module.wasmBinary, imports)
          .then(output => success(output.instance))
          .catch(err => console.error(err));
        return {};
      }
    });

    // Create wrapped function
    const handleRequest = module.cwrap('handle_request', 'string', ['string', 'string']);
    
    // Process request
    const response = handleRequest(method.toUpperCase(), body || "");
    const [headers, content] = response.split('\r\n\r\n');
    
    return new Response(content || "", {
      headers: Object.fromEntries(
        headers.split('\r\n')
          .filter(Boolean)
          .map(h => {
            const [key, value] = h.split(': ');
            return [key.toLowerCase(), value];
          })
      )
    });
  } catch (error) {
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
}

export const config = {
  runtime: 'edge'
};