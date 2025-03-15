import createModule from './tieba.mjs';

export default async function handler(request) {
  try {
    // Initialize the WASM module
    const module = await createModule({ noInitialRun: true });
    const handleRequest = module.cwrap('handle_request', 'string', ['string', 'string']);

    // Extract method and body from the request
    const method = request.method;
    const requestBody = method === 'POST' ? await request.text() : '';

    // Call the C function to handle the request
    const result = handleRequest(method, requestBody);

    // Parse the HTTP response from the C function
    const [headers, responseBody] = result.split('\r\n\r\n', 2);
    return new Response(responseBody, {
      status: parseInt(headers.match(/HTTP\/1.1 (\d+)/)[1], 10),
      headers: headers.split('\r\n').slice(1).reduce((acc, h) => {
        const [key, value] = h.split(': ');
        acc[key] = value;
        return acc;
      }, {})
    });
  } catch (error) {
    console.error('Handler error:', error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
}