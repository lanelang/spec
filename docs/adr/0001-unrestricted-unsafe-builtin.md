# Unrestricted unsafe builtin

Lane2 allows `builtin("...")` as an unsafe expression rather than limiting it to prelude declarations or checking intrinsic names during type checking. It may appear wherever an expression with a direct expected type is accepted, and the checker trusts that expected type instead of interpreting the intrinsic string. This keeps primitive and backend escape hatches simple and available to ordinary code, but it means Lane2's safety guarantees apply only to programs that do not misuse **Unsafe Builtin**.
