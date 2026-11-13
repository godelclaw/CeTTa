/* petta_translator_expansion.h — a PeTTa translator rule run once, where the
 * program is translated.
 *
 * SWI-PeTTa runs a translator rule while it translates the code that calls
 * the rule: the rule receives the call's arguments (an Atom parameter's
 * argument as written), and the code it answers takes the call's place.  The
 * call's variables stay the variables of the code around it, so a value one
 * of them holds when the program runs is never read by the rule and is never
 * evaluated a second time.
 *
 * The expander runs a rule only where its answer is decided by what is
 * written at the call:
 *   - every argument is passed as written (an Atom parameter), or is a
 *     literal or a variable at a parameter with no type guard;
 *   - exactly one equation of the rule is selected, and its head is decided
 *     by the written arguments;
 *   - the body uses only quote, if, ==, car-atom, cdr-atom, cons-atom, let
 *     and let*, each decided by written structure, never by a variable.
 * Any other call declines, and it keeps the translation at each call.
 *
 * The rule's own variables are renamed for each expansion, so two
 * expansions never share a variable and none captures a variable of the
 * call. */
#ifndef CETTA_PETTA_TRANSLATOR_EXPANSION_H
#define CETTA_PETTA_TRANSLATOR_EXPANSION_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "atom.h"

typedef enum {
    /* An Atom parameter: the argument as written. */
    PETTA_TRANSLATOR_ARGUMENT_WRITTEN = 0,
    /* A parameter with no type guard: the argument's value.  A literal or a
     * variable is its own value; anything else declines. */
    PETTA_TRANSLATOR_ARGUMENT_VALUE,
} PettaTranslatorArgument;

typedef enum {
    PETTA_TRANSLATOR_EXPANDED = 0,
    /* The rule's rows are not all ordinary equations of a named head. */
    PETTA_TRANSLATOR_DECLINED_ROWS,
    /* Several signatures, or a guarded parameter. */
    PETTA_TRANSLATOR_DECLINED_SIGNATURE,
    /* An evaluated argument that is neither a literal nor a variable. */
    PETTA_TRANSLATOR_DECLINED_ARGUMENT,
    /* No equation, or more than one, is decided for the call. */
    PETTA_TRANSLATOR_DECLINED_SELECTION,
    /* The body uses a form outside the expander's subset. */
    PETTA_TRANSLATOR_DECLINED_FORM,
    /* A test or a pattern would read a variable's run-time value. */
    PETTA_TRANSLATOR_DECLINED_UNDECIDED,
    /* The program defines one of the forms the expander reads. */
    PETTA_TRANSLATOR_DECLINED_SHADOWED,
    /* The step or size budget ran out. */
    PETTA_TRANSLATOR_DECLINED_BUDGET,
    /* An allocation failed. */
    PETTA_TRANSLATOR_CAPACITY,
    PETTA_TRANSLATOR_OUTCOME_COUNT,
} PettaTranslatorOutcome;

typedef struct {
    void *context;
    /* The rows a call of `head` with `arity` arguments selects among, in
     * declaration order, in a malloc'd array the expander frees.  False
     * declines the call (PETTA_TRANSLATOR_DECLINED_ROWS). */
    bool (*rows)(void *context, Atom *call, Atom ***rows_out,
                 size_t *len_out);
    /* How the call takes each of its `arity` arguments.  False declines
     * (several signatures or a guarded parameter). */
    bool (*arguments)(void *context, Atom *call,
                      PettaTranslatorArgument *modes, size_t arity);
    /* Whether the program gives `head` equations of its own: a program that
     * defines one of the forms the expander reads declines every call. */
    bool (*defines)(void *context, SymbolId head);
} PettaTranslatorOracle;

/* Expand `call`, a call of a translator rule, into `arena`.  On EXPANDED,
 * *generated is the code that takes the call's place: it holds the call's
 * own variables and fresh variables of the rule's. */
PettaTranslatorOutcome petta_translator_expand_call(
    const PettaTranslatorOracle *oracle, Arena *arena, Atom *call,
    Atom **generated);

const char *petta_translator_outcome_name(PettaTranslatorOutcome outcome);

#endif
