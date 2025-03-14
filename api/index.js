export default async function handler(request) {
    const { method } = request;
    const body = method === 'POST' ? await request.text() : null;

    // Import the module factory and instantiate it
    const createModule = (await import('./tieba.js')).default;
    const module = await createModule();
    // Wrap the C function using cwrap
    const handle_request = module.cwrap('handle_request', 'string', ['string', 'string']);

    const response = handle_request(method, body || "");
    const [header, content] = response.split('\r\n\r\n', 2);

    const headers = new Headers();
    header.split('\r\n').forEach(line => {
        const [key, value] = line.split(': ');
        if (key && value) headers.set(key, value);
    });

    return new Response(content, { headers });
}

export const config = {
    runtime: 'edge'
};