# ExBanking
[![Code Checking](https://github.com/maxmaccari/ex_banking/actions/workflows/code-checking.yml/badge.svg)](https://github.com/maxmaccari/ex_banking/actions/workflows/code-checking.yml)
[![Tests](https://github.com/maxmaccari/ex_banking/actions/workflows/tests.yml/badge.svg)](https://github.com/maxmaccari/ex_banking/actions/workflows/tests.yml)
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/maxmaccari/e81dc1a4a2a2f0f532e26ae1c959a7d1/raw/9ef73862e00e6d2ed88122e229ab8606f737aea7/ex_banking_coverage.json)

This project is an OTP implementation of banking accounts with all data persisted in memory.

## Installation

The package can be installed by adding `ex_banking` to your list of dependencies 
in `mix.exs` using the github repository:

```elixir
def deps do
  [
    {:ex_banking, git: "https://github.com/maxmaccari/ex_banking.git"}
  ]
end
```
