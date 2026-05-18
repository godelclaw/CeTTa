!(import! &self str)
!(import! &self str_middle)

!(assertEqual (str-split-middle-bytes "hello world" 5 5) (StrMiddleSplit 1 "hello" "world"))
!(assertEqual (str-split-middle-bytes "abc" 0 0) (StrMiddleSplit 3 "" ""))
!(assertEqual (str-split-middle-bytes "abcdef" 4 4) (StrMiddleSplit 0 "abcd" "ef"))
!(assertEqual (str-split-middle-bytes "😀abc😀" 5 5) (StrMiddleSplit 1 "😀a" "c😀"))
!(assertEqual (str-split-middle-bytes "😀😀😀😀😀" 1 1) (StrMiddleSplit 5 "" ""))
!(assertEqual (str-split-middle-bytes "😀😀😀😀😀" 7 7) (StrMiddleSplit 3 "😀" "😀"))
