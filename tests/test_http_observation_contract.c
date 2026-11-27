/* The HTTP worker's observation contract, against tests/support/io_http_fixture.c
 * (run with its /observe base URL): progress observations, a reply complete
 * before its first observation taken once, a truncated reply whose prefix is
 * not success, separate first-byte, hard and idle deadlines (curl's timeout
 * code, which the application tests for), a refused connection, and exactly
 * one request per case: observing and waiting never resubmit. */
#define _POSIX_C_SOURCE 200809L
#include "http_worker.h"
#include <curl/curl.h>
#include <arpa/inet.h>
#include <assert.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

static uint64_t monotonic_ms(void) {
    struct timespec t;
    assert(clock_gettime(CLOCK_MONOTONIC, &t) == 0);
    return (uint64_t)t.tv_sec * 1000u + (uint64_t)t.tv_nsec / 1000000u;
}

static CettaHttpResult observe_until_complete(CettaHttpWorker *worker, uint64_t id) {
    uint64_t generation = 0, deadline = monotonic_ms() + 10000;
    CettaHttpResult result = {0};
    unsigned observations = 0;
    for (;;) {
        CettaHttpProgress progress;
        assert(cetta_http_worker_progress(worker, id, &progress));
        CettaHttpRead view;
        assert(cetta_http_worker_read(worker, id, 0, 0, &view) == HTTP_READ_OK);
        assert(view.id == id && view.bytes_size == 0);
        cetta_http_read_free(&view);
        ++observations;
        if (cetta_http_worker_take_id(worker, id, &result)) break;
        generation = cetta_http_worker_wait(worker, generation, 5);
        assert(monotonic_ms() < deadline);
    }
    assert(observations > 0 && result.id == id);
    CettaHttpResult duplicate = {0};
    assert(!cetta_http_worker_take_id(worker, id, &duplicate));
    printf("Observed %llu %u code=%d bytes=%zu\n",
           (unsigned long long)id, observations, result.transport_code, result.body_size);
    return result;
}

int main(int argc, char **argv) {
    assert(argc == 2);
    /* A bound socket that never listens: connecting is refused, and holding
     * it keeps the port from being reused meanwhile. */
    int refused = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in address = {.sin_family = AF_INET, .sin_addr.s_addr = htonl(INADDR_LOOPBACK)};
    socklen_t address_size = sizeof(address);
    assert(refused >= 0 && bind(refused, (struct sockaddr *)&address, sizeof(address)) == 0 &&
           getsockname(refused, (struct sockaddr *)&address, &address_size) == 0);
    char refused_url[128];
    snprintf(refused_url, sizeof(refused_url), "http://127.0.0.1:%u/refused", (unsigned)ntohs(address.sin_port));
    /* The application uses this public native code as its timeout discriminator. */
    assert(CURLE_OPERATION_TIMEDOUT == 28);
    CettaHttpWorker *worker = NULL;
    assert(cetta_http_worker_new(NULL, NULL, &worker) == HTTP_WORKER_OK);
    const char *paths[] = {"/progress", "/truncated", "/silent", "/hard", "/ready", "/idle"};
    for (uint64_t i = 0; i < 7; ++i) {
        char url[512];
        if (i == 6) assert(snprintf(url, sizeof(url), "%s", refused_url) < (int)sizeof(url));
        else assert(snprintf(url, sizeof(url), "%s%s", argv[1], paths[i]) < (int)sizeof(url));
        CettaHttpRequest request = {
            .id = i + 1, .method = "POST", .url = url, .body = "one", .body_size = 3,
            .timeout_ms = i == 3 ? 180 : 3000, .connect_timeout_ms = 500,
            .first_byte_timeout_ms = i == 2 ? 80 : 1500,
            .idle_timeout_ms = i == 5 ? 80 : 500, .max_response_bytes = 4096, .proxy = ""
        };
        assert(cetta_http_worker_submit(worker, &request) == HTTP_WORKER_OK);
        if (i == 4) {
            /* Completion can precede the consumer's first observation. */
            CettaHttpProgress progress;
            uint64_t deadline = monotonic_ms() + 5000;
            do {
                assert(cetta_http_worker_progress(worker, request.id, &progress));
                if (progress.terminal) break;
                struct timespec pause = {0, 1000000};
                nanosleep(&pause, NULL);
                assert(monotonic_ms() < deadline);
            } while (true);
            CettaHttpRead view;
            assert(cetta_http_worker_read(worker, request.id, 0, 0, &view) == HTTP_READ_OK);
            assert(view.terminal && view.complete);
            cetta_http_read_free(&view);
        }
        CettaHttpResult result;
        if (i == 4) {
            assert(cetta_http_worker_take_id(worker, request.id, &result));
            CettaHttpResult duplicate = {0};
            assert(!cetta_http_worker_take_id(worker, request.id, &duplicate));
        } else result = observe_until_complete(worker, request.id);
        assert(result.started && !result.cancelled);
        if (i == 0 || i == 4) {
            assert(result.transport_code == CURLE_OK && result.status == 200);
            assert(result.body_size > 0);
        } else if (i == 2 || i == 3 || i == 5) {
            assert(result.transport_code == CURLE_OPERATION_TIMEDOUT);
            if (i == 3 || i == 5) assert(result.body_size > 0);
        } else {
            assert(result.transport_code != CURLE_OK);
            assert(result.transport_code != CURLE_OPERATION_TIMEDOUT);
            if (i == 1) assert(result.body_size > 0); /* a retained prefix is not success */
            if (i == 6) assert(result.transport_code == CURLE_COULDNT_CONNECT);
        }
        cetta_http_result_free(&result);
    }
    /* Exactly one request per case, each with the body it was sent. */
    char counts_url[512];
    assert(snprintf(counts_url, sizeof(counts_url), "%s-counts", argv[1]) < (int)sizeof(counts_url));
    CettaHttpRequest counts = {
        .id = 8, .method = "GET", .url = counts_url, .body = "", .body_size = 0,
        .timeout_ms = 3000, .connect_timeout_ms = 500, .first_byte_timeout_ms = 1500,
        .idle_timeout_ms = 500, .max_response_bytes = 4096, .proxy = ""
    };
    assert(cetta_http_worker_submit(worker, &counts) == HTTP_WORKER_OK);
    CettaHttpResult counted = observe_until_complete(worker, counts.id);
    static const char expected[] = "progress=1 truncated=1 silent=1 hard=1 ready=1 idle=1 bad-bodies=0";
    assert(counted.status == 200 && counted.body_size == sizeof(expected) - 1u &&
           memcmp(counted.body, expected, sizeof(expected) - 1u) == 0);
    cetta_http_result_free(&counted);
    close(refused);
    assert(cetta_http_worker_free(worker) == 0);
    puts("HTTP_OBSERVATION_CONTRACT_OK");
    return 0;
}
