#include <microhttpd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Add strndup for MinGW
#ifdef __MINGW32__
#include <stdlib.h>
#include <string.h>
char* strndup(const char *s, size_t n) {
    char *result;
    size_t len = strlen(s);
    if (n < len) len = n;
    result = malloc(len + 1);
    if (!result) return NULL;
    memcpy(result, s, len);
    result[len] = '\0';
    return result;
}
#endif

// Connection structure
struct connection_info {
    struct MHD_PostProcessor *pp;
    char *user;
    char *caption;
    char *barId;
};

// Rest of your existing code with fixed function signatures
#define PORT 8888
#define MAX_POSTS 1000
#define MAX_USERS 1000

typedef struct {
    char *user;
    char *caption;
    int replies;
    int barId;
} Post;

typedef struct {
    Post posts[MAX_POSTS];
    char *users[MAX_USERS];
    int post_count;
    int user_count;
} Data;

Data data = { .post_count = 0, .user_count = 0 };

struct { int id; const char *name; } bars[] = {
    {43959, "civil engineer bar"},
    {55689, "tsoding fan bar"}
};
const int num_bars = sizeof(bars) / sizeof(bars[0]);

const char *CSS = ".p{outline:solid;padding:1%;margin:1%;max-width:600px}.b{font-weight:bold;margin:0}.c{margin:5px 0}.d{color:#555}.f{font-size:.9em;color:#777}form{margin:1%}input,textarea{display:block;margin:5px}";
const char *FORM = "<form method=\"post\" action=\"/\"><input type=\"text\" name=\"u\" placeholder=\"Your username\" required><textarea name=\"c\" placeholder=\"Your post caption\" required></textarea><input type=\"number\" name=\"b\" placeholder=\"Bar ID (e.g., 43959 or 55689)\"><input type=\"submit\" value=\"Post\"></form>";
const char *HTML_BASE = "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><title>Tieba</title><style>%s</style></head><body>%s%s</body></html>";

// Correct post_iterator with proper return type
static enum MHD_Result post_iterator(void *cls, 
    enum MHD_ValueKind kind, 
    const char *key,
    const char *filename, 
    const char *content_type,
    const char *transfer_encoding, 
    const char *data,
    uint64_t off, 
    size_t size) {
    
    struct connection_info *con_info = cls;
    
    if (strcmp(key, "u") == 0) {
        con_info->user = strndup(data, size);
    } else if (strcmp(key, "c") == 0) {
        con_info->caption = strndup(data, size);
    } else if (strcmp(key, "b") == 0) {
        con_info->barId = strndup(data, size);
    }
    return MHD_YES;
}

void init_data() {
    Post initial[] = {
        {"u1", "i really did", 10, 43959},
        {"u2", "", 10, 0},
        {"u3", "", 5, 0},
        {"u4", "", 3, 0},
        {"u5", "", 7, 0},
        {"u6", "", 2, 55689},
        {"u7", "", 8, 0},
        {"u8", "", 4, 0},
        {"u9", "", 6, 0},
        {"u10", "", 9, 0}
    };
    for (int i = 0; i < 10; i++) {
        data.posts[i].user = strdup(initial[i].user);
        data.posts[i].caption = strdup(initial[i].caption ? initial[i].caption : "");
        data.posts[i].replies = initial[i].replies;
        data.posts[i].barId = initial[i].barId;
        data.users[i] = strdup(initial[i].user);
    }
    data.post_count = 10;
    data.user_count = 10;
}

char *generate_posts_html() {
    char *html = malloc(1024 * data.post_count);
    if (!html) return strdup("Error: Out of memory");
    html[0] = '\0';
    for (int i = 0; i < data.post_count; i++) {
        Post *p = &data.posts[i];
        const char *bar = "";
        for (int j = 0; j < num_bars; j++) {
            if (bars[j].id == p->barId) {
                bar = bars[j].name;
                break;
            }
        }
        char post[256];
        snprintf(post, sizeof(post), 
            "<div class=\"p\" id=\"%s\"><p class=\"b\">%s</p><p class=\"c\">%s r:%d</p><p class=\"d\">body</p><p class=\"f\">%s, Mar 14th 09:30</p></div>",
            p->user, bar, p->caption, p->replies, p->user);
        strcat(html, post);
    }
    return html;
}

enum MHD_Result handle_request(void *cls, struct MHD_Connection *connection,
                              const char *url, const char *method,
                              const char *version, const char *upload_data,
                              size_t *upload_data_size, void **con_cls) {
    struct connection_info *con_info = *con_cls;

    // Initialize connection-specific data
    if (NULL == con_info) {
        con_info = calloc(1, sizeof(struct connection_info));
        if (NULL == con_info) return MHD_NO;
        con_info->pp = MHD_create_post_processor(connection, 1024, post_iterator, con_info);
        if (NULL == con_info->pp) {
            free(con_info);
            return MHD_NO;
        }
        *con_cls = con_info;
        return MHD_YES;
    }

    // Process POST data
    if (strcmp(method, "POST") == 0) {
        if (*upload_data_size > 0) {
            MHD_post_process(con_info->pp, upload_data, *upload_data_size);
            *upload_data_size = 0;
            return MHD_YES;
        } else {
            // Finalize processing after all data is received
            MHD_destroy_post_processor(con_info->pp);
            con_info->pp = NULL;

            // Process collected data
            if (con_info->user && con_info->caption && data.post_count < MAX_POSTS) {
                printf("Adding post: user=%s, caption=%s, barId=%s\n",
                      con_info->user, con_info->caption, con_info->barId);

                int barId = con_info->barId ? atoi(con_info->barId) : 0;
                for (int i = 0; i < num_bars; i++) {
                    if (barId == bars[i].id) {
                        data.posts[data.post_count].barId = barId;
                        break;
                    }
                }

                data.posts[data.post_count].user = strdup(con_info->user);
                data.posts[data.post_count].caption = strdup(con_info->caption);
                data.posts[data.post_count].replies = 0;
                data.post_count++;

                // Add user if new
                if (data.user_count < MAX_USERS) {
                    int exists = 0;
                    for (int i = 0; i < data.user_count; i++) {
                        if (strcmp(data.users[i], con_info->user) == 0) {
                            exists = 1;
                            break;
                        }
                    }
                    if (!exists) {
                        data.users[data.user_count++] = strdup(con_info->user);
                    }
                }
            }

            // Cleanup connection info
            free(con_info->user);
            free(con_info->caption);
            free(con_info->barId);
            free(con_info);
            *con_cls = NULL;
        }
    }

    // Generate response
    char *posts_html = generate_posts_html();
    char *full_html = malloc(strlen(HTML_BASE) + strlen(CSS) + strlen(FORM) + strlen(posts_html) + 1);
    if (full_html) {
        sprintf(full_html, HTML_BASE, CSS, FORM, posts_html);
    } else {
        full_html = strdup("<h1>Server Error: Out of Memory</h1>");
    }
    free(posts_html);

    struct MHD_Response *response = MHD_create_response_from_buffer(
        strlen(full_html), full_html, MHD_RESPMEM_MUST_FREE);
    enum MHD_Result ret = MHD_queue_response(connection, MHD_HTTP_OK, response);
    MHD_destroy_response(response);
    return ret;
}

int main() {
    init_data();
    
    // Get port from environment variable (Vercel requirement)
    const char *port_str = getenv("PORT");
    int port = port_str ? atoi(port_str) : 8888;

    struct MHD_Daemon *daemon = MHD_start_daemon(
        MHD_USE_THREAD_PER_CONNECTION, port, NULL, NULL,
        &handle_request, NULL, MHD_OPTION_END);
    
    if (!daemon) {
        fprintf(stderr, "Failed to start server\n");
        return 1;
    }
    
    printf("Server running on port %d\n", port);
    
    // Vercel-compatible keep-alive
    while(1) {
        sleep(1);
    }
    
    // Cleanup (though this will never be reached)
    MHD_stop_daemon(daemon);
    for (int i = 0; i < data.post_count; i++) {
        free(data.posts[i].user);
        free(data.posts[i].caption);
    }
    for (int i = 0; i < data.user_count; i++) {
        free(data.users[i]);
    }
    
    return 0;
}