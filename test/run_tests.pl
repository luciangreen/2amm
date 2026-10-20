:- prolog_load_context(directory, TestDirectory),
   directory_file_path(TestDirectory, '../prolog', LibraryDirectory),
   absolute_file_name(LibraryDirectory, AbsoluteLibraryDirectory),
   asserta(user:file_search_path(library, AbsoluteLibraryDirectory)).

:- use_module(test_prolog2ann).
:- initialization(main, main).

main :-
    run_tests,
    halt.
