import tiebaModule from './tieba.mjs';

export default async function handler(request) {
  const { method } = request;
  const body = method === 'POST' ? await request.text() : null;

  // Initialize WASM module
  const module = await tiebaModule({
    noInitialRun: true,
    locateFile: (path) => {
      if (path.endsWith('.wasm')) {
        return `data:application/wasm;base64,${Buffer.from(module.wasmBinary).toString('base64')}`;
      }
      return path;
    }
  });

  // Create wrapped function
  const handleRequest = module.cwrap('handle_request', 'string', ['string', 'string']);
  
  // Process request
  const response = handleRequest(method.toUpperCase(), body || "");
  const [statusLine, ...headers] = response.split('\r\n');
  const [_, status] = statusLine.split(' ');
  
  const headersObj = Object.fromEntries(
    headers.map(h => {
      const [key, value] = h.split(': ');
      return [key.toLowerCase(), value];
    })
  );

  return new Response(response.split('\r\n\r\n')[1] || "", {
    status: parseInt(status),
    headers: headersObj
  });
}

export const config = {
  runtime: 'edge'
};