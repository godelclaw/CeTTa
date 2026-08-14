'eval-once'(Expression, Result) :- once(eval(Expression, Result)).
'eval-many'(Result) :- eval([superpose, [20, 22]], Result).
'libpl-double'(Value, Result) :- Result is Value * 2.
'eval-foreign'(Result) :- eval(['libpl-double', 21], Result).
