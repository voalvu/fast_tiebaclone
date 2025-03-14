#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <emscripten.h>

// Data structures
#define MAX_POSTS 1000
#define MAX_USERS 1000
#define BUFFER_SIZE 4096

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

void url_decode(char *dst, const char *src) {
    char a, b;
    while (*src) {
        if ((*src == '%') && (a = src[1]) && (b = src[2]) && isxdigit(a) && isxdigit(b)) {
            if (a >= 'a') a -= 'a'-'A';
            a -= (a >= 'A') ? ('A' - 10) : '0';
            if (b >= 'a') b -= 'a'-'A';
            b -= (b >= 'A') ? ('A' - 10) : '0';
            *dst++ = 16 * a + b;
            src += 3;
        } else {
            *dst++ = *src++;
        }
    }
    *dst = '\0';
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
        data.posts[i].caption = strdup(initial[i].caption);
        data.posts[i].replies = initial[i].replies;
        data.posts[i].barId = initial[i].barId;
        data.users[i] = strdup(initial[i].user);
    }
    data.post_count = 10;
    data.user_count = 10;
}

char *generate_posts_html() {
    char *html = malloc(BUFFER_SIZE * data.post_count);
    if (!html) return strdup("Memory allocation failed");
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
        char post[512];
        snprintf(post, sizeof(post),
            "<div class=\"p\" id=\"%s\"><p class=\"b\">%s</p><p class=\"c\">%s r:%d</p><p class=\"d\">body</p><p class=\"f\">%s, Mar 14th 09:30</p></div>",
            p->user, bar, p->caption, p->replies, p->user);
        strcat(html, post);
    }
    return html;
}

void parse_post_data(const char *input, char **user, char **caption, char **barId) {
    *user = *caption = *barId = NULL;
    if (!input) return;
    
    char decoded[256];
    url_decode(decoded, input);
    
    char *dup = strdup(decoded);
    char *token = strtok(dup, "&");
    
    while (token) {
        char *key = token;
        char *value = strchr(token, '=');
        if (value) {
            *value = '\0';
            value++;
            if (strcmp(key, "u") == 0) *user = strdup(value);
            else if (strcmp(key, "c") == 0) *caption = strdup(value);
            else if (strcmp(key, "b") == 0) *barId = strdup(value);
        }
        token = strtok(NULL, "&");
    }
    free(dup);
}

EMSCRIPTEN_KEEPALIVE
char *handle_request(const char *method, const char *body) {
    static int initialized = 0;
    if (!initialized) {
        init_data();
        initialized = 1;
    }

    char *response = malloc(BUFFER_SIZE);
    if (!response) return strdup("HTTP/1.1 500 Internal Error\r\n\r\nMemory error");

    if (strcmp(method, "GET") == 0) {
        char *posts_html = generate_posts_html();
        if (!posts_html) {
            free(response);
            return strdup("HTTP/1.1 500 Internal Error\r\n\r\nContent generation failed");
        }

        char *content = malloc(strlen(HTML_BASE) + strlen(CSS) + strlen(FORM) + strlen(posts_html) + 1);
        if (!content) {
            free(posts_html);
            free(response);
            return strdup("HTTP/1.1 500 Internal Error\r\n\r\nMemory error");
        }

        sprintf(content, HTML_BASE, CSS, FORM, posts_html);
        snprintf(response, BUFFER_SIZE, "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n%s", content);
        
        free(content);
        free(posts_html);

    } else if (strcmp(method, "POST") == 0 && body) {
        char *user = NULL, *caption = NULL, *barId = NULL;
        parse_post_data(body, &user, &caption, &barId);

        if (user && caption && data.post_count < MAX_POSTS) {
            int bar_id = barId ? atoi(barId) : 0;
            for (int i = 0; i < num_bars; i++) {
                if (bar_id == bars[i].id) {
                    data.posts[data.post_count].barId = bar_id;
                    break;
                }
            }

            data.posts[data.post_count].user = strdup(user);
            data.posts[data.post_count].caption = strdup(caption);
            data.posts[data.post_count].replies = 0;
            data.post_count++;

            if (data.user_count < MAX_USERS) {
                int exists = 0;
                for (int i = 0; i < data.user_count; i++) {
                    if (strcmp(data.users[i], user) == 0) {
                        exists = 1;
                        break;
                    }
                }
                if (!exists) {
                    data.users[data.user_count++] = strdup(user);
                }
            }
        }

        free(user);
        free(caption);
        free(barId);
        strcpy(response, "HTTP/1.1 302 Found\r\nLocation: /\r\n\r\n");

    } else {
        strcpy(response, "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\n\r\nInvalid request");
    }

    return response;
}