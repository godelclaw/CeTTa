#ifndef CETTA_TELEGRAM_AGENT_H
#define CETTA_TELEGRAM_AGENT_H
#include "durable_host.h"
#include "telegram_action.h"

typedef struct {
    const CettaHostProgram *program; /* trusted durable:telegram_agent, version telegram-agent/1 */
    const char *source, *worker;
    const CettaTelegramActionPolicy *actions;
    int fuel;
} CettaTelegramAgent;

/* Native service entry. Selects only fixed receive/reply/completion functions.
 * Derives exact key/prefix grants from recorded input/origin/intent, then checks
 * those routing records again in the ticket's fresh snapshot. Worker data
 * cannot select a program, actor, channel, scope or expression.
 * Returns an evaluated ticket; caller owns it and must require one COMPLETE
 * transition before accepting index 0. No result or a literal Empty means the
 * chat is busy or held; keep its input. Empty is not an acceptable transition.
 * No acceptance, dispatch or SQL occurs here.
 * Action permission failure selects a fixed rejection program on the same
 * ticket, only after a COMPLETE, denial-free result. Each evaluation has the
 * supplied fuel bound; at most two evaluations occur. Other incomplete or
 * malformed results remain uncommittable and require host diagnostics.
 * Host/evaluator thread, fixed HE extended profile; store/program outlive ticket.
 */
CettaDurableStatus cetta_telegram_agent_decide(CettaDurableStore *store,
    const CettaTelegramAgent *agent, const char *input_key, CettaHostDecision **out);
#endif
