#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#ifndef _WIN32
#include <sys/mman.h>
#endif


#define IO_BUF_SIZE (256U << 10U)


typedef struct {
    uint8_t buffer[64];
    uint32_t state[4];
    uint64_t count;
} sha1_ctx;

typedef struct {
    uint8_t buffer[64];
    uint32_t state[4];
    uint64_t count;
} md5_ctx;

typedef void (*initer_t)(void* ctx);
typedef void (*updater_t)(void* ctx, const void* data, uint32_t len);
typedef const uint8_t* (*finisher_t)(void* ctx);

void sha1_init(sha1_ctx*);
void sha1_update(sha1_ctx*, const void*, uint32_t);
const uint8_t* sha1_final(sha1_ctx*);

void md5_init(md5_ctx* ctx);
void md5_update(sha1_ctx*, const void*, uint32_t);
const uint8_t* md5_final(sha1_ctx*);

static char buffer[IO_BUF_SIZE];
static initer_t initer;
static updater_t updater;
static finisher_t finisher;
static md5_ctx ctx5;
static sha1_ctx ctx1;
static void* ctx;
static uint32_t hash_len;


static const char* get_basename(const char* name) {
    const char* p = name;

    for (int i = 0; name[i] != '\0'; i++) {
        const char c = name[i];

        if (c == ':' || c == '\\' || c == '/') {
            p = name + i + 1;
        }
    }

    return p;
}

static void process_file(const char* name)
{
    int handle;
    const char* error_msg = "Cannot open file";
    const char* const bn = get_basename(name);

    handle = open(name, O_RDONLY);
    if (handle != -1) {
        ssize_t red;

        error_msg = NULL;

#ifndef _WIN32
        posix_fadvise(handle, 0, 0, POSIX_FADV_SEQUENTIAL);
#endif

        initer(&ctx);

        red = read(handle, buffer, IO_BUF_SIZE);
        while (red > 0) {
            updater(&ctx, buffer, (uint32_t)red);
            red = read(handle, buffer, IO_BUF_SIZE);
        }

        if (red == 0) {
            const uint8_t* const p = finisher(&ctx);
            for (uint32_t i = 0U; i < hash_len; i++) {
                printf("%02x", p[i]);
            }
            printf(" <- %s\n", bn);
        }
        else {
            error_msg = "Cannot read file";
        }

        close(handle);
    }

    if (error_msg != NULL) {
        printf("%s: %s\n", bn, error_msg);
    }
}

int main(int argc, char* argv[])
{
    int exit_code = 0;

    if ((argc >= 3)
        && ((strcmp(argv[1], "-md5") == 0) || (strcmp(argv[1], "-sha1") == 0)))
    {
        if (argv[1][1] == 'm') {
            initer = (initer_t)&md5_init;
            updater = (updater_t)&md5_update;
            finisher = (finisher_t)&md5_final;
            ctx = &ctx5;
            hash_len = 16U;
        }
        else {
            initer = (initer_t)&sha1_init;
            updater = (updater_t)&sha1_update;
            finisher = (finisher_t)&sha1_final;
            ctx = &ctx1;
            hash_len = 20U;
        }

#ifndef _WIN32
#ifndef __CYGWIN__
        mlockall(MCL_CURRENT);
#else
        mlock(&buffer, IO_BUF_SIZE);
#endif
#endif

        for (int i = 2; i < argc; i++) {
            struct stat s;
            if ((stat(argv[i], &s) != 0) || (S_ISDIR(s.st_mode) == 0U)) {
                process_file(argv[i]);
            }
        }
    }
    else {
        puts("Enter: badsum <-md5|-sha1> <file[s]>");
        exit_code++;
    }
    
    return exit_code;
}
