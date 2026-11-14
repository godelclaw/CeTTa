/* Qualification-only instrumentation, inserted into a private evaluator.
 * Records reached publication entries, including the caller's ELF offset.
 * Entries may be forwarded or refused later; this is not a commit proof. */
#include <dlfcn.h>
#include <inttypes.h>

static bool eval_failure_values(void);

static void ai_audit_record(const char *file, int line, const char *function,
        Atom *value, CettaCallResultForm form, bool he, void *caller) {
    if (!eval_failure_values() ||
        (!atom_is_error(value) && form != CETTA_CALL_RESULT_RAISED))
        return;
    unsigned role = form == CETTA_CALL_RESULT_RAISED ? 0u
        : atom_is_he_evaluated(value) ? 1u
        : form == CETTA_CALL_RESULT_EXPRESSION ||
          form == CETTA_CALL_RESULT_EXPRESSION_FRONTIER ? 2u : 3u;
    const char *path = getenv("CETTA_AI_PROVENANCE_LOG");
    FILE *log = path && *path ? fopen(path, "a") : NULL;
    if (!log) {
        fputs("provenance audit destination unavailable\n", stderr);
        abort();
    }
    const char *names[] = {"raised", "data", "expression", "unclassified"};
    Dl_info image = {0};
    uintptr_t offset = caller && dladdr(caller, &image) && image.dli_fbase
        ? (uintptr_t)caller - (uintptr_t)image.dli_fbase : 0u;
    fprintf(log, "%s\t%d\t%s\t%s\t%s\t0x%" PRIxPTR "\n", file, line,
        function, he ? "he" : "petta", names[role], offset);
    if (fclose(log) != 0)
        abort();
}

#define AI_AUDIT_RECORD(value_, form_) \
    ai_audit_record(__FILE__, __LINE__, __func__, (value_), (form_), \
        eval_current_language_id() == CETTA_LANGUAGE_HE, NULL)
#define AI_AUDIT_ENTRY(value_, form_) \
    ai_audit_record(__FILE__, __LINE__, __func__, (value_), (form_), \
        eval_current_language_id() == CETTA_LANGUAGE_HE, \
        __builtin_extract_return_addr(__builtin_return_address(0)))
