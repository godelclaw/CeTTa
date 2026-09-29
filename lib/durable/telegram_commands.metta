!(import! &self str)
!(import! &self json)
!(import! &self durable:telegram)

; Operator commands of telegram-channel/1. A deployment declares them as
; data, which the host loads from a file of declarations only:
;   (tg-cmd:command NAME KIND HELP)
;   (tg-cmd:agent NAME)      optional: how replies name the agent
;   (tg-cmd:bot USERNAME)    optional: accept /command@USERNAME
; NAME is "/" and 1..32 of a-z, 0-9 and "_". KIND is one of
;   help       the service lists the declared commands;
;   stop       the service stops dispatching the agent's sends, answers at
;              once and tells the agent;
;   start      the service resumes dispatch, answers at once and tells the
;              agent;
;   delegated  the agent answers. The service owns a deadline: if the agent
;              has not answered by then, the service replies with its own
;              notice and edits it when the answer arrives.
; An operator's message whose text is a declared command, optionally with
; arguments, is a command. Anything else is ordinary input.

; The message text as a plain string. A command is printable text without
; quotes or backslashes, so the JSON literal of such a text, without its
; quotes, is the text itself; a text needing any escape is not a command.
(= (tg-cmd:text $update)
   (case (telegram:field $update "message")
     (((tg:some $message)
       (case (telegram:field $message "text")
         (((tg:some (JsonStringV1 $scalars))
           (let $literal (json:stringify (JsonStringV1 $scalars))
             (case (str:find $literal "\\")
               (((TextNotFound $needle)
                 (tg:some (str:slice $literal 1 (- (str:length $literal) 1))))
                ($found tg:none)))))
          ($other tg:none))))
      ($other tg:none))))

(= (tg-cmd:kind $name)
   (case (collapse (match &self (tg-cmd:command $name $kind $help) $kind))
     ((($kind) (tg:some $kind))
      ($other tg:none))))

; /name or /name@bot, when bot is the declared username.
(= (tg-cmd:addressee $head)
   (case (str:split "@" $head)
     ((($name) (tg:some $name))
      (($name $bot)
       (if (== (collapse (match &self (tg-cmd:bot $bot) True)) (True)) (tg:some $name) tg:none))
      ($other tg:none))))

(= (tg-cmd:parse $text)
   (case (str:split-whitespace $text)
     ((() tg:none)
      ($words
       (let ($head $rest) (decons-atom $words)
         (if (not (str:starts-with $head "/")) tg:none
           (case (tg-cmd:addressee $head)
             (((tg:some $name)
               (case (tg-cmd:kind $name)
                 (((tg:some $kind) (tg-cmd:call $name $kind (str:join " " $rest)))
                  ($unknown tg:none))))
              ($other tg:none)))))))))

; The command an update carries, if its sender is an operator.
(= (tg-cmd:of $kind $role $update)
   (if (and (== $kind "message") (== $role operator))
     (case (tg-cmd:text $update)
       (((tg:some $text) (tg-cmd:parse $text))
        ($none tg:none)))
     tg:none))

(= (tg-cmd:agent-name)
   (case (collapse (match &self (tg-cmd:agent $name) $name))
     ((($name) $name)
      ($other "the agent"))))

(= (tg-cmd:named $kind)
   (case (collapse (match &self (tg-cmd:command $name $kind $help) $name))
     ((($name) $name)
      ($other ""))))

(= (tg-cmd:help-text)
   (str:join "\n" (collapse (match &self (tg-cmd:command $name $kind $help)
                              (format-args "{} — {}" ($name $help))))))

(= (tg-cmd:stopped-text)
   (let $agent (tg-cmd:agent-name)
     (let $start (tg-cmd:named start)
       (format-args "Stopped. Nothing {} submits is sent until {}." ($agent $start)))))

(= (tg-cmd:started-text)
   (let $agent (tg-cmd:agent-name)
     (format-args "Started. {}'s messages go out again." ($agent))))

(= (tg-cmd:fallback-text)
   (let $agent (tg-cmd:agent-name)
     (format-args "No answer from {} yet. This message will be updated when it arrives." ($agent))))

; The agent's answer: ["answer", text]. Longer text is cut to fit one
; message; an empty answer is said so. Anything else is no answer.
(= (tg-cmd:answer-text $body)
   (case (json-parse $body)
     (((JsonArray ((JsonString "answer") (JsonString $text)))
       (let $length (str:length $text)
         (if (== $length 0) (tg:some "(empty answer)")
           (if (> $length 3800) (tg:some (str:slice $text 0 3800)) (tg:some $text)))))
      ($other tg:none))))

; The agent's task for a command: ["command", key, name, arguments]. Names
; are declared; arguments contain no quote, backslash or control character.
(= (tg-cmd:observation $key $name $args)
   (format-args "[\"command\",\"{}\",\"{}\",\"{}\"]" ($key $name $args)))

; The lifecycle latch, read from the given view.
(= (tg-cmd:stopped $view)
   (== (collapse (match &self (host:record $view "latch" (tg-cmd:latch stopped)) True)) (True)))
