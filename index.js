import createModule from './tieba.mjs';

export default async function handler(request) {
  try {
    // Initialize the WASM module asynchronously
    const module = await createModule({
      noInitialRun: true // Prevents the module from running automatically on instantiation
    });

    // Example: Call a function from your C code
    const handleRequest = module.cwrap('handle_request', 'string', ['string']);
    const result = handleRequest("some input");

    return new Response(result, { status: 200 });
  } catch (error) {
    console.error('Handler error:', error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
}