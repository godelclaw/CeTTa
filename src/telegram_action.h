#ifndef CETTA_TELEGRAM_ACTION_H
#define CETTA_TELEGRAM_ACTION_H
#include "durable_dispatch.h"

enum { TELEGRAM_SEND_TEXT=1, TELEGRAM_EDIT_TEXT=2, TELEGRAM_DELETE_MESSAGE=4 };
typedef struct {
    const int64_t *chats;
    size_t chat_count; /* 1..128 explicit numeric destinations */
    unsigned methods; /* positive permission mask, no administrative methods */
} CettaTelegramActionPolicy;

/* Native validation/marshalling for channel telegram.action, handler 1.
 * Use the same immutable policy as the acceptance validator context and the
 * dispatch planner context. Dispatch revalidates independently. Payloads:
 * (telegram:send-text 1 chat thread reply-message "text" "plain|HTML|MarkdownV2")
 * (telegram:edit-text 1 chat message "text" "plain|HTML|MarkdownV2")
 * (telegram:delete-message 1 chat message)
 * Zero thread/reply omits that option; edit/delete message IDs are positive.
 * Text is valid UTF-8, 1..4096 Unicode scalars including any markup. This is
 * conservative for formatted text; Telegram also validates its entity syntax.
 * No arbitrary JSON, method, URL, token, file or parse/eval entry is accepted.
 * The trusted application owns default routing, chunking, message ownership,
 * ordering and retry policy. Edit/delete authority is chat-wide.
 */
bool cetta_telegram_action_validate(void *context, const Atom *payload, const Atom *reply);
bool cetta_telegram_action_plan(void *context, Arena *arena, const Atom *payload,
                                const Atom *reply, CettaTelegramPlan *out);
#endif
