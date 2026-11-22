; Rows where the core build of candidate 7 differs from SWI-Prolog 10.1.9 (swipl, catch/3). Expected lines are SWI results; this file is meant to FAIL until Gem fixes or documents the builtin. Never edit expected lines to match CeTTa.
!(catch (term_hash foo 1 0))
!(catch (term_hash foo 1 2147483648))
