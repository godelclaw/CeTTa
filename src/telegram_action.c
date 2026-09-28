#define _POSIX_C_SOURCE 200809L
#include "telegram_action.h"
#include <inttypes.h>
#include <stdio.h>
#include <string.h>

typedef struct {
    unsigned method;
    int64_t chat, thread, message;
    const char *text, *format;
    size_t bytes;
} Action;
static bool integer(const Atom *a, int64_t *n) {
    if (!a || a->kind!=ATOM_GROUNDED || a->ground.gkind!=GV_INT) return false;
    *n=a->ground.ival; return true;
}
static const char *string(const Atom *a) {
    return a && a->kind==ATOM_GROUNDED && a->ground.gkind==GV_STRING?a->ground.sval:NULL;
}
static bool message_text(const char *text, size_t *bytes) {
    if (!text) return false;
    size_t n=strnlen(text,16385), scalars=0;
    if (!n || n>16384) return false;
    const unsigned char *s=(const unsigned char *)text;
    for (size_t i=0;i<n;) {
        if (++scalars>4096) return false;
        unsigned c=s[i++], more, min;
        if (c<128) continue;
        if (c>=0xc2 && c<=0xdf) { more=1; min=0x80; c&=31; }
        else if (c>=0xe0 && c<=0xef) { more=2; min=0x800; c&=15; }
        else if (c>=0xf0 && c<=0xf4) { more=3; min=0x10000; c&=7; }
        else return false;
        if (more>n-i) return false;
        while (more--) { unsigned d=s[i++]; if ((d&0xc0)!=0x80) return false; c=(c<<6)|(d&63); }
        if (c<min || c>0x10ffff || (c>=0xd800 && c<=0xdfff)) return false;
    }
    *bytes=n; return true;
}
static bool decode(const CettaTelegramActionPolicy *policy, const Atom *p, Action *a) {
    if (!policy || !policy->chats || !policy->chat_count || policy->chat_count>128 ||
        (policy->methods & ~7u) || !p || p->kind!=ATOM_EXPR || p->expr.len<4) return false;
    Atom **v=p->expr.elems; int64_t version;
    if (!integer(v[1],&version) || version!=1 || !integer(v[2],&a->chat) || !a->chat) return false;
    bool allowed=false;
    for (size_t i=0;i<policy->chat_count;++i) if (policy->chats[i]==a->chat) allowed=true;
    if (!allowed) return false;
    if (atom_is_symbol(v[0],"telegram:send-text") && p->expr.len==7) {
        a->method=TELEGRAM_SEND_TEXT;
        if (!integer(v[3],&a->thread) || a->thread<0 || !integer(v[4],&a->message) || a->message<0) return false;
        a->text=string(v[5]); a->format=string(v[6]);
    } else if (atom_is_symbol(v[0],"telegram:edit-text") && p->expr.len==6) {
        a->method=TELEGRAM_EDIT_TEXT;
        if (!integer(v[3],&a->message) || a->message<=0) return false;
        a->text=string(v[4]); a->format=string(v[5]);
    } else if (atom_is_symbol(v[0],"telegram:delete-message") && p->expr.len==4) {
        a->method=TELEGRAM_DELETE_MESSAGE;
        if (!integer(v[3],&a->message) || a->message<=0) return false;
    } else return false;
    if (!(policy->methods&a->method)) return false;
    return a->method==TELEGRAM_DELETE_MESSAGE ||
        (a->format && (!strcmp(a->format,"plain") || !strcmp(a->format,"HTML") || !strcmp(a->format,"MarkdownV2")) &&
         message_text(a->text,&a->bytes));
}
bool cetta_telegram_action_validate(void *context, const Atom *payload, const Atom *reply) {
    (void)reply; Action a={0}; return decode(context,payload,&a);
}
/* Fixed keys/numeric fields plus one escaped string: no JSON parser or
 * evaluator is involved, and user bytes cannot introduce another field. */
static char *quoted(char *out, const char *text) {
    static const char hex[]="0123456789abcdef";
    *out++='"';
    for (const unsigned char *s=(const unsigned char *)text; *s; ++s) {
        if (*s=='"' || *s=='\\') { *out++='\\'; *out++=(char)*s; }
        else if (*s<32) {
            memcpy(out,"\\u00",4); out+=4; *out++=hex[*s>>4]; *out++=hex[*s&15];
        } else *out++=(char)*s;
    }
    *out++='"'; return out;
}
bool cetta_telegram_action_plan(void *context, Arena *arena, const Atom *payload,
                                const Atom *reply, CettaTelegramPlan *out) {
    (void)reply;
    if (!out) return false;
    *out=(CettaTelegramPlan){0}; Action a={0};
    if (!arena || !decode(context,payload,&a)) return false;
    /* Worst-case control escaping plus fixed keys, three int64 fields and
     * a validated format name. All sizes are bounded before allocation. */
    char *body=arena_alloc(arena,a.bytes*6+512), *end=body;
    end+=sprintf(end,"{\"chat_id\":%" PRId64,a.chat);
    const char *method=a.method==TELEGRAM_SEND_TEXT?"sendMessage":
        a.method==TELEGRAM_EDIT_TEXT?"editMessageText":"deleteMessage";
    if (a.method==TELEGRAM_SEND_TEXT) {
        if (a.thread) end+=sprintf(end,",\"message_thread_id\":%" PRId64,a.thread);
        if (a.message) end+=sprintf(end,",\"reply_parameters\":{\"message_id\":%" PRId64 "}",a.message);
    } else end+=sprintf(end,",\"message_id\":%" PRId64,a.message);
    if (a.text) {
        memcpy(end,",\"text\":",8); end=quoted(end+8,a.text);
        if (strcmp(a.format,"plain")) end+=sprintf(end,",\"parse_mode\":\"%s\"",a.format);
    }
    *end++='}'; *end=0;
    *out=(CettaTelegramPlan){method,"application/json",body,(size_t)(end-body)};
    return true;
}
